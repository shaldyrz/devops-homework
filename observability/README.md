# Observability (Grafana Stack)

This directory contains observability configuration as code for dashboards, alerting rules, and notification routes managed using the Grafana stack.

## Components

- **Dashboards**: JSON model definitions or provisioning configuration files for Grafana dashboards.
- **Alerting Rules**: Definitions for alerting thresholds and criteria (e.g., latency anomalies, error rates, service health) using Grafana Alerting.
- **Alerting Routes & Receivers**: Configurations specifying how alerts are routed to different channels (e.g., Slack, Email, PagerDuty, Webhooks) based on labels and severity.

## Getting Started

1. **Local Setup & Development**:
   - Ensure the Grafana stack is running or accessible.
   - Deploy/import dashboards and rules using your CI pipeline or Terraform/Grafana provisioning configs.
2. **Editing Dashboards**:
   - Make edits in the Grafana UI, export the dashboard JSON, and save it in the dashboard folder here to keep it version-controlled.
