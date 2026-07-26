import os
import re
import math
import time
import logging
import requests
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from starlette.concurrency import run_in_threadpool
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rag-api")

MODEL_SERVER_URL = os.environ.get("MODEL_SERVER_URL", "http://localhost:8001")
CORPUS_DIR = os.environ.get("CORPUS_DIR", "./corpus")

app = FastAPI(title="meridian RAG API service")

REQUESTS = Counter(
    "rag_requests_total", "Requests handled by the RAG API", ["route", "status"]
)
LATENCY = Histogram(
    "rag_request_duration_seconds",
    "RAG API request latency",
    ["route"],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0],
)

# Global variables for corpus and indexing
paragraphs = []
doc_tokens = []
idf = {}

STOPWORDS = {"what", "is", "the", "of", "and", "to", "in", "for", "with", "a", "an", "who", "which", "how", "often", "must", "be", "by", "or", "at", "are", "about", "from", "on", "as", "if"}
DOMAIN_WORDS = set() # Will be populated after stem function is defined

def stem(word):
    word = word.lower()
    return word[:6] if len(word) > 6 else word

DOMAIN_WORDS = {stem(w) for w in {"meridian", "fund", "invest", "guideline", "portfolio", "document", "guidelines", "fixed", "income", "global", "equity"}}

def tokenize(text):
    words = re.findall(r'\w+', text.lower())
    return [stem(w) for w in words if w not in STOPWORDS]

@app.on_event("startup")
def load_corpus():
    global paragraphs, doc_tokens, idf
    logger.info(f"Loading corpus from {CORPUS_DIR}...")
    if not os.path.exists(CORPUS_DIR):
        logger.error(f"Corpus directory {CORPUS_DIR} not found!")
        return

    documents = []
    for filename in os.listdir(CORPUS_DIR):
        if filename.endswith(".md"):
            path = os.path.join(CORPUS_DIR, filename)
            logger.info(f"Reading file: {filename}")
            with open(path, "r", encoding="utf-8") as f:
                documents.append(f.read())

    # Split into paragraphs by double newlines
    for doc in documents:
        parts = re.split(r'\n\s*\n', doc)
        for part in parts:
            part = part.strip()
            if part:
                paragraphs.append(part)

    logger.info(f"Extracted {len(paragraphs)} paragraphs.")

    # Build TF-IDF index
    doc_tokens = [tokenize(p) for p in paragraphs]
    N = len(paragraphs)

    df = {}
    for tokens in doc_tokens:
        unique_tokens = set(tokens)
        for token in unique_tokens:
            df[token] = df.get(token, 0) + 1

    for token, count in df.items():
        idf[token] = math.log(1 + N / count)
    
    logger.info("TF-IDF indexing completed.")

def retrieve(query, k=3):
    query_tokens = tokenize(query)
    scores = []
    for idx, tokens in enumerate(doc_tokens):
        score = 0.0
        for token in query_tokens:
            if token in idf:
                tf = tokens.count(token)
                weight = 0.1 if token in DOMAIN_WORDS else 1.0
                score += tf * idf[token] * weight
        scores.append((idx, score))
    
    scores.sort(key=lambda x: x[1], reverse=True)
    return [paragraphs[idx] for idx, score in scores[:k]]

@app.get("/healthz")
async def healthz():
    try:
        # Check upstream model-server status as well
        upstream = requests.get(f"{MODEL_SERVER_URL}/healthz", timeout=2)
        upstream_ok = upstream.status_code == 200
    except Exception:
        upstream_ok = False
    
    status_code = 200 if upstream_ok else 503
    return JSONResponse(
        {"status": "ok" if upstream_ok else "degraded", "model_server": upstream_ok},
        status_code=status_code
    )

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    started = time.perf_counter()
    status = "200"
    try:
        payload = await request.json()
        messages = payload.get("messages", [])
        
        # Extract user query
        user_message_idx = -1
        query = ""
        for idx, message in enumerate(reversed(messages)):
            if message.get("role") == "user":
                user_message_idx = len(messages) - 1 - idx
                query = str(message.get("content", ""))
                break

        if user_message_idx == -1 or not query:
            status = "400"
            return JSONResponse({"error": {"message": "no user message found", "type": "invalid_request"}}, status_code=400)

        # Retrieve relevant paragraphs
        retrieved_paragraphs = retrieve(query, k=3)
        context_block = "\n---\n".join(retrieved_paragraphs)

        # Format grounded prompt
        grounded_prompt = f"{query}\n\nContext:\n{context_block}"
        
        # Update payload user message content
        payload["messages"][user_message_idx]["content"] = grounded_prompt
        logger.info(f"Forwarding grounded prompt for query: '{query[:50]}...'")

        # Forward request to mock inference server
        try:
            upstream_response = await run_in_threadpool(
                requests.post,
                f"{MODEL_SERVER_URL}/v1/chat/completions",
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            status = str(upstream_response.status_code)
            return JSONResponse(upstream_response.json(), status_code=upstream_response.status_code)
        except requests.RequestException as exc:
            logger.error(f"Error connecting to model server: {exc}")
            status = "502"
            return JSONResponse(
                {"error": {"message": f"model server unreachable: {exc}", "type": "bad_gateway"}},
                status_code=502
            )
    finally:
        REQUESTS.labels(route="/v1/chat/completions", status=status).inc()
        LATENCY.labels(route="/v1/chat/completions").observe(
            time.perf_counter() - started
        )
