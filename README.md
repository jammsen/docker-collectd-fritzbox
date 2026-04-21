## Docker - Grafana InfluxDB and Collectd with FritzBox plugin
This includes a preconfigured Collectd including the Python plugin fritzcollectd, based on Docker. Also included a Docker Compose file to get fast up and monitoring.

## The following examples / configs are included
* Docker Compose file
* Collectd config
* InfluxDB config and types.db for Collectd
* Grafana dashboard

## What you need to run this
* Basic understanding of Docker (Docker Compose) and Grafana

## Getting started
1. Clone project
2. Copy `.env.example` to `.env` and fill in your values
3. Configure `compose.yml` if needed
4. Run: `docker compose up` or `docker compose up -d`
5. Go to http://dockerhostip:3000 and log in with `admin` / `admin` (or whatever you set as `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` in your `.env`) — Grafana will prompt you to change the password on first login
6. The InfluxDB data source is automatically provisioned — no manual configuration needed
7. Import the dashboard: go to **Dashboards → New → Import**, click **Upload dashboard JSON file**, and select `grafana-dashboard.json` from this repository

## Software used
* Ubuntu 24.04 LTS
* InfluxDB v1.12 (v2+ removed the native collectd UDP listener)
* Grafana v11
* Collectd
* Python 3
* fritzcollectd