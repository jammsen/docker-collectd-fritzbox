## Docker - Grafana, InfluxDB and Collectd with FritzBox plugin

A fully self-contained monitoring stack for AVM FritzBox routers. Collects router metrics via the fritzcollectd plugin, stores them in InfluxDB, and displays them in a pre-provisioned Grafana dashboard — no manual Grafana configuration needed.

## What's included

- `compose.yml` — Docker Compose stack (Grafana, InfluxDB, collectd-fritzbox)
- `collectd-fritzbox/` — Dockerfile and config for the collectd container
- `influxdb.conf` / `types.db` — InfluxDB configuration and collectd type definitions
- `grafana/provisioning/` — Auto-provisioned datasource and dashboard (no manual import needed)
- `.env.example` — Template for all required environment variables

## Requirements

- Docker with Docker Compose
- A host machine IP reachable from the collectd container (used for `INFLUXDB_HOST`)
- A FritzBox router with TR-064 / UPnP enabled and a dedicated user

## Getting started

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your values:
   ```
   cp .env.example .env
   ```
3. Key variables to set in `.env`:

   | Variable | Description |
   |---|---|
   | `INFLUXDB_HOST` | Host machine IP (not `localhost` — collectd uses host networking) |
   | `INFLUXDB_ADMIN_USER` / `INFLUXDB_ADMIN_PASSWORD` | InfluxDB credentials |
   | `FRITZBOX_IP` | FritzBox LAN IP (usually `192.168.178.1`) |
   | `FRITZBOX_USER` / `FRITZBOX_PASSWORD` | FritzBox user with TR-064 access |
   | `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` | Grafana login (default: `admin`/`admin`) |

4. Start the stack (builds the collectd-fritzbox image locally):
   ```
   docker compose up -d --build
   ```
5. Open Grafana at **http://&lt;your-host&gt;:3000** and log in with your configured credentials.
   - The InfluxDB datasource is auto-provisioned on first start
   - The FritzBox dashboard is auto-provisioned on first start — no import needed

## Data persistence

Grafana and InfluxDB data are stored in `grafana_data/` and `influxdb_data/` on the host. To start completely fresh, stop the stack and remove those directories:

```
docker compose down
rm -rf grafana_data/* influxdb_data/*
docker compose up -d --build
```

## Software versions

| Component | Version |
|---|---|
| Ubuntu | 24.04 LTS (collectd base image) |
| InfluxDB | 1.12 (v2+ removed the native collectd UDP listener) |
| Grafana | 13.0.1 |
| collectd | system package |
| fritzcollectd | 0.7.0 (pinned) |
| fritzconnection | 0.8.5 (pinned; patched for lxml ≥5) |
| Python | 3 |

## Patches applied to upstream dependencies

### `fritzconnection-lxml5.patch` — fritzconnection 0.8.x + lxml ≥5 compatibility

**File:** `collectd-fritzbox/fritzconnection-lxml5.patch`  
**Applied to:** `fritzconnection` 0.8.x (`fritzconnection/fritzconnection.py`)  
**Applied during:** Docker image build (`collectd-fritzbox/Dockerfile`)

#### The problem

`fritzconnection` 0.8.x fetches TR-064 XML configuration files from the FritzBox using `lxml`. In `FritzXmlParser.__init__`:

```python
source = 'http://192.168.178.1:49000/igddesc.xml'
tree = etree.parse(source)   # lxml fetches the URL directly
self.root = tree.getroot()
```

lxml ≥5.0 (released ~2024) introduced a **security hardening change**: it no longer allows `etree.parse()` to fetch remote HTTP URLs. It raises:

```
OSError: failed to load "http://192.168.178.1:49000/igddesc.xml": Attempt to load network entity
```

Ubuntu 24.04 ships with lxml ≥5, so any fresh install pulls the incompatible version. The FritzBox is perfectly reachable — the issue is entirely inside Python.

#### Call flow

**Before (broken with lxml ≥5):**

```
FritzConnection.__init__()
  └─ _read_descriptions()
       └─ FritzDescParser(address, port, 'igddesc.xml')
            └─ FritzXmlParser.__init__()
                 ├─ builds source = "http://192.168.178.1:49000/igddesc.xml"
                 └─ etree.parse(source)  ← lxml ≥5 BLOCKS this, raises OSError
                      ↓
                 fritzcollectd catches OSError → "Failed to connect"
```

**After the patch:**

```
FritzConnection.__init__()
  └─ _read_descriptions()
       └─ FritzDescParser(address, port, 'igddesc.xml')
            └─ FritzXmlParser.__init__()
                 ├─ builds source = "http://192.168.178.1:49000/igddesc.xml"
                 ├─ detects it starts with "http"
                 ├─ requests.get(source)  ← plain HTTP fetch, always worked
                 └─ etree.fromstring(response.content)  ← parse bytes in memory, no URL loading
                      ↓
                 self.root populated correctly → collectd reads FritzBox data
```

The `else` branch keeps `etree.parse(source)` for the local-file case (used in unit tests where a filename path is passed instead of an address).

#### Why the patch lives in the Dockerfile

`fritzconnection` 0.8.5 is abandoned (last release 2018) and its API changed incompatibly in 1.0, which `fritzcollectd` 0.7.0 doesn't support. Upgrading either package would require rewriting the collectd plugin config. The patch is the minimal surgical fix.