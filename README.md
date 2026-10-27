<div align="center">

<img src="assets/logo.png" alt="Zoraxy CrowdSec Bouncer logo" width="140" />

**Zoraxy reverse proxy with the CrowdSec bouncer plugin pre-installed — ready for Unraid and Docker.**<br>
*Zoraxy-Reverse-Proxy mit vorinstalliertem CrowdSec-Bouncer-Plugin — fertig für Unraid und Docker.*

[![Build](https://github.com/s3lfcod3r/zoraxy-crowdsec-bouncer/actions/workflows/docker-build.yml/badge.svg)](https://github.com/s3lfcod3r/zoraxy-crowdsec-bouncer/actions/workflows/docker-build.yml)
[![Auto-Update](https://github.com/s3lfcod3r/zoraxy-crowdsec-bouncer/actions/workflows/auto-update.yml/badge.svg)](https://github.com/s3lfcod3r/zoraxy-crowdsec-bouncer/actions/workflows/auto-update.yml)
[![License](https://img.shields.io/badge/license-All%20rights%20reserved%20%2B%20third%20party-8A9CAA)](LICENSE)
![Version](https://img.shields.io/badge/version-3.3.5-33A78C)
![Zoraxy](https://img.shields.io/badge/zoraxy-v3.3.5--rc4-1F7763)
![Plugin](https://img.shields.io/badge/plugin-v1.2.3-43D3AD)
![Deploy](https://img.shields.io/badge/deploy-GHCR%20%E2%86%92%20Unraid-6F95AD)

**[🇬🇧 English](#-english) · [🇩🇪 Deutsch](#-deutsch)**

📰 **What's new / Neuigkeiten** → [CHANGELOG.md](CHANGELOG.md)

</div>

---

<a id="-english"></a>

## 🇬🇧 English

This Docker image combines [Zoraxy](https://github.com/tobychui/zoraxy) — a modern HTTP reverse proxy — with the [CrowdSec bouncer plugin](https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer), which blocks malicious IPs automatically. It is for Unraid and Docker users who already run (or want to run) CrowdSec. **CrowdSec itself is not included** — you need your own CrowdSec instance (LAPI).

Part of the **Self** family (SelfMailer, SelfStream, SelfArchiver, SelfDashboard …) — same deploy style (GHCR → Unraid).

> **TL;DR** — plugin pre-installed · `config.yaml` from container variables · auto-update every 12 h · CrowdSec not included

### 📑 Table of contents

[Features](#en-features) · [Architecture](#en-architecture) · [Quick start](#en-quick-start) · [Unraid](#en-unraid) · [Configuration](#en-configuration) · [CrowdSec setup](#en-crowdsec) · [Activate the plugin](#en-plugin) · [Troubleshooting](#en-troubleshooting) · [Security](#en-security) · [Tech stack](#en-tech-stack) · [Development](#en-development) · [Roadmap](#en-roadmap)

<a id="en-features"></a>

### ✨ Features

**🧱 Image**
- **Plugin pre-installed** — no manual download, no compiling
- **`config.yaml` generated automatically** — written from the container variables on every start
- **Auto-update** — a workflow checks for new Zoraxy / plugin versions every 12 h and rebuilds only on updates

**📦 Unraid**
- **Template** with masked API key field, ports and paths
- Listed in **Community Applications** (`zoraxy-crowdsec-bouncer`)

| Component | Version |
|---|---|
| Zoraxy | kept up to date automatically (`ARG ZORAXY_VERSION` in the [`Dockerfile`](Dockerfile)) |
| CrowdSec bouncer plugin | kept up to date automatically (`ARG PLUGIN_VERSION` in the [`Dockerfile`](Dockerfile)) |

<a id="en-architecture"></a>

### 🧭 Architecture

```text
Internet ──▶ ┌─ Zoraxy container (this image) ───────────────┐
             │  Reverse proxy ──▶ CrowdSec bouncer plugin ───┼──▶ your services
             │        │                    ▲                 │
             └────────┼────────────────────┼─────────────────┘
                      │ writes zr_*.log    │ asks for bans (API key)
                      ▼                    │
                 Access logs               │
                      │ acquis.yaml,       │
                      │ read-only mount    │
             ┌────────▼────────────────────┴─────────────────┐
             │  CrowdSec container (separate)                │
             │  parsers + scenarios ──▶ LAPI / decisions     │
             └───────────────────────────────────────────────┘
```

**Key point:** without the log path, CrowdSec never learns about new attackers — the bouncer then only blocks what is already in the LAPI. This is by far the most common misconfiguration, see [CrowdSec setup, step 2](#en-crowdsec).

<a id="en-quick-start"></a>

### 🚀 Quick start (Docker)

```bash
docker pull ghcr.io/s3lfcod3r/zoraxy-crowdsec-bouncer:latest
```

For a local test, use this `docker-compose.yml` (the repo version builds the image itself):

```yaml
services:
  zoraxy:
    image: ghcr.io/s3lfcod3r/zoraxy-crowdsec-bouncer:latest
    container_name: zoraxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8000:8000"
    volumes:
      - ./config:/opt/zoraxy/config/
      - ./plugin:/opt/zoraxy/plugin/
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      - CROWDSEC_API_KEY=YOUR_API_KEY
      - CROWDSEC_AGENT_URL=http://crowdsec:8080
      - CROWDSEC_LOG_LEVEL=warning
      - CROWDSEC_CLOUDFLARE=false
      - FASTGEOIP=true
      - DOCKER=true
```

Open `http://<host>:8000` → Zoraxy web UI, then [activate the plugin](#en-plugin).

<a id="en-unraid"></a>

### 📦 Unraid

**Method 1 — Community Applications:** search for `zoraxy-crowdsec-bouncer`, click **Install**, adjust the settings below.

**Method 2 — add the template manually:** *Docker → Add Container*, paste under **Template URL**
`https://raw.githubusercontent.com/s3lfcod3r/zoraxy-crowdsec-bouncer/main/unraid/zoraxy-crowdsec-bouncer.xml`
and click **Load**.

<details><summary><b>Setup — Unraid settings in detail</b></summary>

**Required fields (always visible)**

| Field | Example | Description |
|---|---|---|
| **CrowdSec API Key** | `abc123xyz...` | Hidden while typing (masked) |
| **CrowdSec Agent URL** | `http://192.168.1.100:8080` | IP of your CrowdSec container |
| **WebUI Port** | `8000` | Zoraxy management UI |
| **HTTP Port** | `80` | HTTP traffic |
| **HTTPS Port** | `443` | HTTPS traffic |
| **Config Folder** | `/mnt/user/appdata/zoraxy/config` | Zoraxy configuration data |
| **Plugin Folder** | `/mnt/user/appdata/zoraxy/plugin` | Plugin incl. `config.yaml` |

**Advanced fields**

| Field | Default | Description |
|---|---|---|
| Log Level | `warning` | How much the bouncer logs |
| Cloudflare Proxy | `false` | `true` if you use Cloudflare |
| Fast GeoIP | `true` | GeoIP database |
| Docker Mode | `true` | Docker compatibility |

**Changing ports** — if port 80 or 443 is already in use:

| Field | Default | Example | Note |
|---|---|---|---|
| Host Port HTTP | `80` | `8080` | Only change the host port, container port stays `80` |
| Host Port HTTPS | `443` | `8443` | Only change the host port, container port stays `443` |
| Host Port WebUI | `8000` | `9000` | Zoraxy management UI |

**Changing paths**

| Field | Default | Alternative (SSD/cache) |
|---|---|---|
| Config path | `/mnt/user/appdata/zoraxy/config` | `/mnt/cache/appdata/zoraxy/config` |
| Plugin path | `/mnt/user/appdata/zoraxy/plugin` | `/mnt/cache/appdata/zoraxy/plugin` |

> **💡 Tip:** use `/mnt/cache/appdata/` if you have an SSD as cache drive — it's faster.

</details>

> **⚠️ Ports:** only change the **left** value (host port), never the right one (container port).

<a id="en-configuration"></a>

### ⚙️ Configuration

Environment variables, entered directly in Unraid (or docker-compose).

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `CROWDSEC_API_KEY` | ✅ | – | API key of your CrowdSec instance |
| `CROWDSEC_AGENT_URL` | ✅ | `http://crowdsec:8080` | URL of your CrowdSec instance |
| `CROWDSEC_LOG_LEVEL` | – | `warning` | `trace` / `debug` / `info` / `warning` / `error` |
| `CROWDSEC_CLOUDFLARE` | – | `false` | `true` if Zoraxy runs behind Cloudflare |
| `FASTGEOIP` | – | `true` | Fast GeoIP database |
| `DOCKER` | – | `true` | Docker compatibility mode |

> **💡 Tip:** the plugin `config.yaml` is **rewritten on every start** from these variables. Manual edits are overwritten — change the values in Unraid instead.

**Ports**

| Port | Purpose |
|---|---|
| `80` | HTTP traffic |
| `443` | HTTPS traffic |
| `8000` | Zoraxy web UI (management) |

**Volumes**

| Container path | Purpose | Unraid default |
|---|---|---|
| `/opt/zoraxy/config/` | Zoraxy config, certificates, logs | `/mnt/user/appdata/zoraxy/config` |
| `/opt/zoraxy/plugin/` | Plugin data incl. generated `config.yaml` | `/mnt/user/appdata/zoraxy/plugin` |
| `/var/run/docker.sock` | Docker socket (Docker mode) | `/var/run/docker.sock` |
| `/etc/localtime` | Time zone from the host | `/etc/localtime` |

<a id="en-crowdsec"></a>

### 🧩 CrowdSec setup (prerequisite)

This image only ships the **bouncer inside Zoraxy** — CrowdSec runs separately. Overview:

1. Install the CrowdSec container (Community Applications)
2. Feed Zoraxy **logs** into CrowdSec (`acquis.yaml` + volume)
3. Install the Zoraxy **collection** from the hub (parser for `type: zoraxy`)
4. Create a **bouncer** → put the API key into this image
5. Zoraxy container: LAPI URL + plugin + **tags**

> **💡 Tip:** CrowdSec on Unraid (IBRACORP template): [docs.ibracorp.io](https://docs.ibracorp.io) · Zoraxy thread: [tobychui/zoraxy#338](https://github.com/tobychui/zoraxy/discussions/338)

<details><summary><b>Setup — CrowdSec step by step</b></summary>

**Step 1 — CrowdSec from Community Applications**

1. Open **Community Applications** in Unraid
2. Search for **`crowdsec`** (publisher **crowdsecurity**, maintainer e.g. IBRACORP)
3. Install and start the container
4. Note the **container name** (often `crowdsec`) and the host config path (e.g. `/mnt/user/Docker/crowdsec/` or `/mnt/user/appdata/crowdsec/`)

The LAPI usually listens on port **8080**.

**Step 2 — expose Zoraxy logs to CrowdSec**

CrowdSec must read the Zoraxy access logs (`zr_*.log`, monthly rollover). You need a **volume** on the CrowdSec container and an **`acquis.yaml`**.

Add a **path** mapping on the CrowdSec container (adjust to your setup):

| Host path (example) | Container path | Mode |
|---|---|---|
| `/mnt/user/appdata/zoraxy/config/log` | `/var/log/zoraxy` | `ro` |

**Finding the host path:** use the folder that contains the `zr_*.log` files — often a `log/` subfolder of the Zoraxy **config** volume. Example from a working setup: host config under `/mnt/user/Docker/crowdsec/`, Zoraxy logs from the config volume mounted to `/var/log/zoraxy` in the CrowdSec container.

Create `acquis.yaml` in the CrowdSec config folder on the host, e.g. `/mnt/user/Docker/crowdsec/acquis.yaml` (wherever your template maps `/etc/crowdsec`):

```yaml
---
filenames:
  - "/var/log/zoraxy/zr_*.log"   ## all Zoraxy logs (monthly rollover)
labels:
  type: "zoraxy"                 ## must match the installed parser
```

Paths in `filenames` are **inside the CrowdSec container** (`/var/log/zoraxy/...`), not the Unraid host path. Some setups use `/etc/crowdsec/acquis.d/` instead — put the same YAML there, e.g. as `zoraxy.yaml`. **Restart the CrowdSec container** afterwards.

**Step 3 — install the Zoraxy collection (parser)**

```bash
docker exec -it crowdsec cscli collections install raithmir/zoraxy-logs
```

Hub: [Raithmir – zoraxy collection](https://app.crowdsec.net/hub/author/Raithmir/collections/zoraxy). Optional checks:

```bash
docker exec -it crowdsec cscli collections list
docker exec -it crowdsec cscli metrics
```

**Step 4 — network: Zoraxy ↔ CrowdSec LAPI**

The Zoraxy container must reach the CrowdSec **LAPI** (port 8080).

- *Option A — same custom Docker network (recommended):* both containers on one network, then e.g. `CROWDSEC_AGENT_URL=http://crowdsec:8080` (`crowdsec` = container name).
- *Option B — bridge / different networks:* use the IP of the Unraid host or the CrowdSec container, e.g. `CROWDSEC_AGENT_URL=http://192.168.1.10:8080`.

**Step 5 — create the bouncer and connect Zoraxy**

```bash
docker exec -it crowdsec cscli bouncers add zoraxy-bouncer
```

Copy the shown **API key** into the Zoraxy CrowdSec Bouncer container (**CrowdSec API Key**), set **CrowdSec Agent URL** to the LAPI URL from step 4, then restart the Zoraxy container.

**Step 6 — verify the chain**

```bash
# bouncer registered?
docker exec -it crowdsec cscli bouncers list

# decisions arriving? (after some traffic through Zoraxy)
docker exec -it crowdsec cscli decisions list

# metrics / parsers running?
docker exec -it crowdsec cscli metrics
```

If `decisions list` stays empty: check logs first (`acquis.yaml`, volume, `zr_*.log` path) and the collection — **no logs, no new bans**.

</details>

<a id="en-plugin"></a>

### 🏷️ Activate the plugin

After the first start:

1. Open the Zoraxy web UI: `http://YOUR-UNRAID-IP:8000`
2. Go to **Plugins** — the CrowdSec bouncer should appear → **activate**
3. Go to **Tags** → create a new tag (e.g. `crowdsec-protected`)
4. Add the tag to every proxy rule you want to protect

<a id="en-troubleshooting"></a>

### 🩺 Troubleshooting

| Symptom | What to check |
|---|---|
| **Plugin not shown in the web UI** | Plugin path mounted correctly? Restart the container. |
| **`config.yaml` has the wrong API key** | Delete `/mnt/user/appdata/zoraxy/plugin/zoraxycrowdsecbouncer/config.yaml` and restart — it is recreated from the current variables. |
| **CrowdSec API not reachable** | Zoraxy and CrowdSec in the same Docker network? Otherwise use the direct IP: `http://192.168.1.xxx:8080` |
| **No bans / empty `cscli decisions list`** | Zoraxy logs mounted into CrowdSec (`/var/log/zoraxy/zr_*.log` visible in the container)? `acquis.yaml` with `type: zoraxy`? `cscli collections install raithmir/zoraxy-logs` done? Traffic going through proxy rules with the plugin **tag**? |
| **Port already in use** | Change the host port in the Unraid container settings (left value only!) |

> **💡 Tip:** the plugin files are copied into the plugin volume **only if the plugin binary is missing there**. To get a newer plugin version from the image, delete `/mnt/user/appdata/zoraxy/plugin/zoraxycrowdsecbouncer/` and restart the container.

<a id="en-security"></a>

### 🛡️ Security

- **Bouncer** blocks IPs that CrowdSec has decided on (LAPI decisions), per proxy rule via **tags**
- **API key masked** in the Unraid template
- **Pinned versions** (`ARG ZORAXY_VERSION` / `ARG PLUGIN_VERSION`) — every update is a visible commit
- **Deliberate trade-offs** (documented): the **Docker socket** is mounted for Zoraxy's Docker mode (gives the container control over Docker — remove the mount if you don't need it); the API key is stored **in plain text** in the plugin `config.yaml` on the volume; the auto-update follows Zoraxy **release candidates** too

Security update history → [CHANGELOG.md](CHANGELOG.md) (entries marked 🔒).

<a id="en-tech-stack"></a>

### 🧱 Tech stack

| Part | Tech |
|---|---|
| Base image | `zoraxydocker/zoraxy` (Alpine) |
| Plugin | [zoraxy_crowdsec_bouncer](https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer) (prebuilt binary) |
| Start | `entrypoint.sh` (POSIX shell) |
| Deploy | GitHub Actions · GHCR · Unraid |

<a id="en-development"></a>

### 🛠️ Development

| Path | Purpose |
|---|---|
| `Dockerfile` | Builds Zoraxy + bouncer plugin into one image |
| `entrypoint.sh` | Writes the plugin `config.yaml` from the ENV variables on start |
| `docker-compose.yml` | Local test without Unraid |
| `unraid/zoraxy-crowdsec-bouncer.xml` | Unraid container template |
| `ca_profile.xml` | Maintainer profile for Unraid Community Applications |
| `.github/workflows/` | Image build (`docker-build.yml`) + version auto-update (`auto-update.yml`) |

```bash
docker compose up -d --build
```

<a id="en-roadmap"></a>

### 🗺️ Roadmap

- [x] Plugin pre-installed, `config.yaml` from variables
- [x] Unraid template + Community Applications
- [x] Auto-update every 12 h, rebuild only on updates
- [x] Image on own GHCR account

<p align="right"><a href="#-english">⬆ back to top</a></p>

---

<a id="-deutsch"></a>

## 🇩🇪 Deutsch

Dieses Docker-Image kombiniert [Zoraxy](https://github.com/tobychui/zoraxy) — einen modernen HTTP-Reverse-Proxy — mit dem [CrowdSec-Bouncer-Plugin](https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer), das bösartige IPs automatisch blockiert. Es ist für Unraid- und Docker-Nutzer, die CrowdSec schon betreiben (oder betreiben wollen). **CrowdSec selbst ist nicht enthalten** — du brauchst eine eigene CrowdSec-Instanz (LAPI).

Teil der **Self**-Familie (SelfMailer, SelfStream, SelfArchiver, SelfDashboard …) — gleicher Deploy-Stil (GHCR → Unraid).

> **Kurz** — Plugin vorinstalliert · `config.yaml` aus Container-Variablen · Auto-Update alle 12 h · CrowdSec nicht enthalten

### 📑 Inhaltsverzeichnis

[Funktionen](#de-funktionen) · [Architektur](#de-architektur) · [Schnellstart](#de-schnellstart) · [Unraid](#de-unraid) · [Konfiguration](#de-konfiguration) · [CrowdSec einrichten](#de-crowdsec) · [Plugin aktivieren](#de-plugin) · [Häufige Probleme](#de-probleme) · [Sicherheit](#de-sicherheit) · [Tech-Stack](#de-tech-stack) · [Entwicklung](#de-entwicklung) · [Roadmap](#de-roadmap)

<a id="de-funktionen"></a>

### ✨ Funktionen

**🧱 Image**
- **Plugin vorinstalliert** — kein manueller Download, kein Kompilieren
- **`config.yaml` automatisch** — wird bei jedem Start aus den Container-Variablen geschrieben
- **Auto-Update** — ein Workflow prüft alle 12 h auf neue Zoraxy-/Plugin-Versionen und baut nur bei Updates neu

**📦 Unraid**
- **Vorlage** mit verstecktem API-Key-Feld, Ports und Pfaden
- In den **Community Applications** gelistet (`zoraxy-crowdsec-bouncer`)

| Komponente | Version |
|---|---|
| Zoraxy | wird automatisch aktuell gehalten (`ARG ZORAXY_VERSION` im [`Dockerfile`](Dockerfile)) |
| CrowdSec-Bouncer-Plugin | wird automatisch aktuell gehalten (`ARG PLUGIN_VERSION` im [`Dockerfile`](Dockerfile)) |

<a id="de-architektur"></a>

### 🧭 Architektur

```text
Internet ──▶ ┌─ Zoraxy-Container (dieses Image) ─────────────┐
             │  Reverse-Proxy ──▶ CrowdSec-Bouncer-Plugin ───┼──▶ deine Dienste
             │        │                    ▲                 │
             └────────┼────────────────────┼─────────────────┘
                      │ schreibt zr_*.log  │ fragt Bans ab (API-Key)
                      ▼                    │
                 Access-Logs               │
                      │ acquis.yaml,       │
                      │ read-only Mount    │
             ┌────────▼────────────────────┴─────────────────┐
             │  CrowdSec-Container (separat)                 │
             │  Parser + Szenarien ──▶ LAPI / Entscheidungen │
             └───────────────────────────────────────────────┘
```

**Kernpunkt:** Ohne den Log-Weg lernt CrowdSec nie neue Angreifer — der Bouncer blockt dann nur, was in der LAPI schon steht. Das ist mit Abstand der häufigste Konfigurationsfehler, siehe [CrowdSec einrichten, Schritt 2](#de-crowdsec).

<a id="de-schnellstart"></a>

### 🚀 Schnellstart (Docker)

```bash
docker pull ghcr.io/s3lfcod3r/zoraxy-crowdsec-bouncer:latest
```

Für einen lokalen Test diese `docker-compose.yml` nehmen (die Version im Repo baut das Image selbst):

```yaml
services:
  zoraxy:
    image: ghcr.io/s3lfcod3r/zoraxy-crowdsec-bouncer:latest
    container_name: zoraxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8000:8000"
    volumes:
      - ./config:/opt/zoraxy/config/
      - ./plugin:/opt/zoraxy/plugin/
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      - CROWDSEC_API_KEY=DEIN_API_KEY
      - CROWDSEC_AGENT_URL=http://crowdsec:8080
      - CROWDSEC_LOG_LEVEL=warning
      - CROWDSEC_CLOUDFLARE=false
      - FASTGEOIP=true
      - DOCKER=true
```

`http://<host>:8000` öffnen → Zoraxy-Weboberfläche, dann [Plugin aktivieren](#de-plugin).

<a id="de-unraid"></a>

### 📦 Unraid

**Methode 1 — Community Applications:** nach `zoraxy-crowdsec-bouncer` suchen, **Install** klicken, Einstellungen wie unten anpassen.

**Methode 2 — Vorlage von Hand:** *Docker → Add Container*, unter **Template URL**
`https://raw.githubusercontent.com/s3lfcod3r/zoraxy-crowdsec-bouncer/main/unraid/zoraxy-crowdsec-bouncer.xml`
einfügen und **Load** klicken.

<details><summary><b>Einrichtung — Unraid-Einstellungen im Detail</b></summary>

**Pflichtfelder (immer sichtbar)**

| Feld | Beispiel | Beschreibung |
|---|---|---|
| **CrowdSec API Key** | `abc123xyz...` | Wird beim Eintippen versteckt |
| **CrowdSec Agent URL** | `http://192.168.1.100:8080` | IP deines CrowdSec-Containers |
| **WebUI Port** | `8000` | Zoraxy-Verwaltungsoberfläche |
| **HTTP Port** | `80` | HTTP-Traffic |
| **HTTPS Port** | `443` | HTTPS-Traffic |
| **Config Folder** | `/mnt/user/appdata/zoraxy/config` | Zoraxy-Konfiguration |
| **Plugin Folder** | `/mnt/user/appdata/zoraxy/plugin` | Plugin inkl. `config.yaml` |

**Erweiterte Felder**

| Feld | Standard | Beschreibung |
|---|---|---|
| Log Level | `warning` | Wie viel der Bouncer protokolliert |
| Cloudflare Proxy | `false` | `true`, wenn du Cloudflare nutzt |
| Fast GeoIP | `true` | GeoIP-Datenbank |
| Docker Mode | `true` | Docker-Kompatibilität |

**Ports ändern** — falls Port 80 oder 443 schon belegt ist:

| Feld | Standard | Beispiel | Hinweis |
|---|---|---|---|
| Host Port HTTP | `80` | `8080` | Nur den Host-Port ändern, Container-Port bleibt `80` |
| Host Port HTTPS | `443` | `8443` | Nur den Host-Port ändern, Container-Port bleibt `443` |
| Host Port WebUI | `8000` | `9000` | Zoraxy-Verwaltungsoberfläche |

**Pfade ändern**

| Feld | Standard | Alternative (SSD/Cache) |
|---|---|---|
| Config-Pfad | `/mnt/user/appdata/zoraxy/config` | `/mnt/cache/appdata/zoraxy/config` |
| Plugin-Pfad | `/mnt/user/appdata/zoraxy/plugin` | `/mnt/cache/appdata/zoraxy/plugin` |

> **💡 Tipp:** Nimm `/mnt/cache/appdata/`, wenn du eine SSD als Cache-Laufwerk hast — das ist schneller.

</details>

> **⚠️ Ports:** Ändere **nur** den linken Wert (Host-Port), nie den rechten (Container-Port).

<a id="de-konfiguration"></a>

### ⚙️ Konfiguration

Umgebungsvariablen, direkt in Unraid (oder docker-compose) eintragen.

| Variable | Pflicht | Standard | Zweck |
|---|---|---|---|
| `CROWDSEC_API_KEY` | ✅ | – | API-Key deiner CrowdSec-Instanz |
| `CROWDSEC_AGENT_URL` | ✅ | `http://crowdsec:8080` | URL deiner CrowdSec-Instanz |
| `CROWDSEC_LOG_LEVEL` | – | `warning` | `trace` / `debug` / `info` / `warning` / `error` |
| `CROWDSEC_CLOUDFLARE` | – | `false` | `true`, wenn Zoraxy hinter Cloudflare läuft |
| `FASTGEOIP` | – | `true` | Schnelle GeoIP-Datenbank |
| `DOCKER` | – | `true` | Docker-Kompatibilitätsmodus |

> **💡 Tipp:** Die Plugin-`config.yaml` wird **bei jedem Start** aus diesen Variablen neu geschrieben. Änderungen von Hand gehen verloren — Werte also lieber in Unraid pflegen.

**Ports**

| Port | Zweck |
|---|---|
| `80` | HTTP-Traffic |
| `443` | HTTPS-Traffic |
| `8000` | Zoraxy-Weboberfläche (Verwaltung) |

**Volumes**

| Container-Pfad | Zweck | Unraid-Standard |
|---|---|---|
| `/opt/zoraxy/config/` | Zoraxy-Konfiguration, Zertifikate, Logs | `/mnt/user/appdata/zoraxy/config` |
| `/opt/zoraxy/plugin/` | Plugin-Daten inkl. erzeugter `config.yaml` | `/mnt/user/appdata/zoraxy/plugin` |
| `/var/run/docker.sock` | Docker-Socket (Docker-Modus) | `/var/run/docker.sock` |
| `/etc/localtime` | Zeitzone vom Host | `/etc/localtime` |

<a id="de-crowdsec"></a>

### 🧩 CrowdSec einrichten (Voraussetzung)

Dieses Image enthält **nur den Bouncer in Zoraxy** — CrowdSec läuft getrennt. Überblick:

1. CrowdSec-Container installieren (Community Applications)
2. Zoraxy-**Logs** in CrowdSec einbinden (`acquis.yaml` + Volume)
3. Zoraxy-**Collection** aus dem Hub installieren (Parser für `type: zoraxy`)
4. **Bouncer** anlegen → API-Key in dieses Image eintragen
5. Zoraxy-Container: LAPI-URL + Plugin + **Tags**

> **💡 Tipp:** CrowdSec auf Unraid (IBRACORP-Vorlage): [docs.ibracorp.io](https://docs.ibracorp.io) · Zoraxy-Diskussion: [tobychui/zoraxy#338](https://github.com/tobychui/zoraxy/discussions/338)

<details><summary><b>Einrichtung — CrowdSec Schritt für Schritt</b></summary>

**Schritt 1 — CrowdSec aus den Community Applications**

1. In Unraid **Community Applications** öffnen
2. Nach **`crowdsec`** suchen (Herausgeber **crowdsecurity**, Maintainer z. B. IBRACORP)
3. Container installieren und starten
4. Merken: **Container-Name** (oft `crowdsec`) und wo die Config auf dem Host liegt (z. B. `/mnt/user/Docker/crowdsec/` oder `/mnt/user/appdata/crowdsec/`)

Die LAPI ist meist auf Port **8080** erreichbar.

**Schritt 2 — Zoraxy-Logs für CrowdSec freigeben**

CrowdSec muss die Zoraxy-Access-Logs lesen (`zr_*.log`, monatlicher Wechsel). Dafür brauchst du ein **Volume** im CrowdSec-Container und eine **`acquis.yaml`**.

Im CrowdSec-Container einen **Pfad** hinzufügen (an dein Setup anpassen):

| Host-Pfad (Beispiel) | Container-Pfad | Modus |
|---|---|---|
| `/mnt/user/appdata/zoraxy/config/log` | `/var/log/zoraxy` | `ro` |

**Host-Pfad finden:** den Ordner mit den `zr_*.log`-Dateien nehmen — oft ein Unterordner `log/` im Zoraxy-**Config**-Volume. Beispiel aus einem funktionierenden Setup: Host-Config unter `/mnt/user/Docker/crowdsec/`, Zoraxy-Logs vom Config-Volume nach `/var/log/zoraxy` im CrowdSec-Container eingebunden.

`acquis.yaml` im CrowdSec-Config-Ordner auf dem Host anlegen, z. B. `/mnt/user/Docker/crowdsec/acquis.yaml` (dort, wo deine Vorlage `/etc/crowdsec` einbindet):

```yaml
---
filenames:
  - "/var/log/zoraxy/zr_*.log"   ## alle Zoraxy-Logs (monatlicher Wechsel)
labels:
  type: "zoraxy"                 ## muss zum installierten Parser passen
```

Der Pfad in `filenames` ist der **Pfad im CrowdSec-Container** (`/var/log/zoraxy/...`), nicht der Unraid-Host-Pfad. Manche Setups nutzen statt einer einzelnen `acquis.yaml` den Ordner `/etc/crowdsec/acquis.d/` — dann dasselbe YAML z. B. als `zoraxy.yaml` dort ablegen. **CrowdSec-Container danach neu starten.**

**Schritt 3 — Zoraxy-Collection (Parser) installieren**

```bash
docker exec -it crowdsec cscli collections install raithmir/zoraxy-logs
```

Hub: [Raithmir – zoraxy collection](https://app.crowdsec.net/hub/author/Raithmir/collections/zoraxy). Optional prüfen:

```bash
docker exec -it crowdsec cscli collections list
docker exec -it crowdsec cscli metrics
```

**Schritt 4 — Netzwerk: Zoraxy ↔ CrowdSec-LAPI**

Der Zoraxy-Container muss die CrowdSec-**LAPI** erreichen (Port 8080).

- *Option A — gleiches eigenes Docker-Netzwerk (empfohlen):* beide Container im selben Netzwerk, dann z. B. `CROWDSEC_AGENT_URL=http://crowdsec:8080` (`crowdsec` = Container-Name).
- *Option B — Bridge / verschiedene Netzwerke:* IP des Unraid-Hosts oder des CrowdSec-Containers nehmen, z. B. `CROWDSEC_AGENT_URL=http://192.168.1.10:8080`.

**Schritt 5 — Bouncer anlegen und Zoraxy verbinden**

```bash
docker exec -it crowdsec cscli bouncers add zoraxy-bouncer
```

Den angezeigten **API-Key** im Zoraxy-CrowdSec-Bouncer-Container eintragen (**CrowdSec API Key**), **CrowdSec Agent URL** auf die LAPI-URL aus Schritt 4 setzen, danach den Zoraxy-Container neu starten.

**Schritt 6 — prüfen, ob die Kette funktioniert**

```bash
# Bouncer registriert?
docker exec -it crowdsec cscli bouncers list

# Kommen Entscheidungen an? (nach etwas Traffic über Zoraxy)
docker exec -it crowdsec cscli decisions list

# Laufen Metriken / Parser?
docker exec -it crowdsec cscli metrics
```

Bleibt `decisions list` leer: zuerst die Logs (`acquis.yaml`, Volume, `zr_*.log`-Pfad) und die Collection prüfen — **ohne Logs keine neuen Bans**.

</details>

<a id="de-plugin"></a>

### 🏷️ Plugin aktivieren

Nach dem ersten Start:

1. Zoraxy-Weboberfläche öffnen: `http://DEINE-UNRAID-IP:8000`
2. Zu **Plugins** gehen — der CrowdSec-Bouncer sollte erscheinen → **aktivieren**
3. Zu **Tags** gehen → neuen Tag anlegen (z. B. `crowdsec-protected`)
4. Den Tag bei allen Proxy-Regeln setzen, die geschützt werden sollen

<a id="de-probleme"></a>

### 🩺 Häufige Probleme

| Symptom | Was zu prüfen ist |
|---|---|
| **Plugin erscheint nicht in der Weboberfläche** | Plugin-Pfad richtig eingebunden? Container neu starten. |
| **`config.yaml` hat den falschen API-Key** | `/mnt/user/appdata/zoraxy/plugin/zoraxycrowdsecbouncer/config.yaml` löschen und neu starten — sie wird mit den aktuellen Variablen neu erstellt. |
| **CrowdSec-API nicht erreichbar** | Zoraxy und CrowdSec im selben Docker-Netzwerk? Sonst direkte IP: `http://192.168.1.xxx:8080` |
| **Keine Bans / leere `cscli decisions list`** | Zoraxy-Logs in CrowdSec eingebunden (`/var/log/zoraxy/zr_*.log` im Container sichtbar)? `acquis.yaml` mit `type: zoraxy` da? `cscli collections install raithmir/zoraxy-logs` ausgeführt? Läuft Traffic über Proxy-Regeln mit dem Plugin-**Tag**? |
| **Port schon belegt** | Host-Port in den Unraid-Container-Einstellungen ändern (nur den linken Wert!) |

> **💡 Tipp:** Die Plugin-Dateien werden **nur dann** ins Plugin-Volume kopiert, wenn die Plugin-Datei dort fehlt. Für eine neuere Plugin-Version aus dem Image `/mnt/user/appdata/zoraxy/plugin/zoraxycrowdsecbouncer/` löschen und den Container neu starten.

<a id="de-sicherheit"></a>

### 🛡️ Sicherheit

- **Bouncer** blockt IPs, über die CrowdSec entschieden hat (LAPI-Entscheidungen), pro Proxy-Regel über **Tags**
- **API-Key versteckt** in der Unraid-Vorlage
- **Feste Versionen** (`ARG ZORAXY_VERSION` / `ARG PLUGIN_VERSION`) — jedes Update ist ein sichtbarer Commit
- **Bewusste Kompromisse** (dokumentiert): Der **Docker-Socket** ist für den Docker-Modus von Zoraxy eingebunden (gibt dem Container Macht über Docker — Einbindung entfernen, wenn du sie nicht brauchst); der API-Key liegt **im Klartext** in der Plugin-`config.yaml` im Volume; das Auto-Update folgt auch **Vorabversionen** (Release Candidates) von Zoraxy

Verlauf der Sicherheitsupdates → [CHANGELOG.md](CHANGELOG.md) (Einträge mit 🔒).

<a id="de-tech-stack"></a>

### 🧱 Tech-Stack

| Teil | Technik |
|---|---|
| Basis-Image | `zoraxydocker/zoraxy` (Alpine) |
| Plugin | [zoraxy_crowdsec_bouncer](https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer) (fertig gebaute Datei) |
| Start | `entrypoint.sh` (POSIX-Shell) |
| Deploy | GitHub Actions · GHCR · Unraid |

<a id="de-entwicklung"></a>

### 🛠️ Entwicklung

| Pfad | Zweck |
|---|---|
| `Dockerfile` | Baut Zoraxy + Bouncer-Plugin in ein Image |
| `entrypoint.sh` | Schreibt beim Start die Plugin-`config.yaml` aus den ENV-Variablen |
| `docker-compose.yml` | Lokaler Test ohne Unraid |
| `unraid/zoraxy-crowdsec-bouncer.xml` | Unraid-Container-Vorlage |
| `ca_profile.xml` | Maintainer-Profil für die Unraid Community Applications |
| `.github/workflows/` | Image-Bau (`docker-build.yml`) + Versions-Auto-Update (`auto-update.yml`) |

```bash
docker compose up -d --build
```

<a id="de-roadmap"></a>

### 🗺️ Roadmap

- [x] Plugin vorinstalliert, `config.yaml` aus Variablen
- [x] Unraid-Vorlage + Community Applications
- [x] Auto-Update alle 12 h, Neubau nur bei Updates
- [x] Image auf eigenem GHCR-Konto

<p align="right"><a href="#-deutsch">⬆ nach oben</a></p>

---

## ⚖️ Lizenz / License

**🇩🇪 Alle Rechte vorbehalten.** © 2026 s3lfcod3r / SelfCoder

Du darfst die Software **privat und nicht-kommerziell** installieren und benutzen (z. B. im Homelab, über Docker oder Unraid).

**Ohne schriftliche Erlaubnis verboten:** kommerzielle Nutzung · Kopieren · Verändern · Weitergeben · Einbauen in eigene Projekte (auch Closed Source) · Verkaufen.

Das gilt nur für die Dateien in diesem Repository (Dockerfile, Skripte, Vorlagen, Doku). Zoraxy (AGPL-3.0), das CrowdSec-Bouncer-Plugin (MIT) und CrowdSec (MIT) behalten ihre eigenen Lizenzen — siehe *Credits* unten.

Details: [LICENSE](LICENSE)

**🇬🇧 All rights reserved.** © 2026 s3lfcod3r / SelfCoder

You may install and use the software **privately and non-commercially** (e.g. in your home lab, via Docker or Unraid).

**Not permitted without written permission:** commercial use · copying · modifying · redistributing · incorporating into other projects (including closed source) · selling.

This covers only the files in this repository (Dockerfile, scripts, templates, docs). Zoraxy (AGPL-3.0), the CrowdSec bouncer plugin (MIT) and CrowdSec (MIT) keep their own licenses — see *Credits* below.

Details: [LICENSE](LICENSE)

### Credits

| Project | Author | License | Link |
|---|---|---|---|
| Zoraxy | tobychui | AGPL v3 | https://github.com/tobychui/zoraxy |
| zoraxy_crowdsec_bouncer | AnthonyMichaelTDM | MIT | https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer |
| CrowdSec | CrowdSec | MIT | https://github.com/crowdsecurity/crowdsec |

**MIT License – zoraxy_crowdsec_bouncer** · Copyright (c) 2025 Anthony Rubick

Dieses Docker-Image / diese Vorlage wird unabhängig gepflegt und ist nicht mit den oben genannten Projekten verbunden.
This Docker image / template is independently maintained and is not affiliated with the projects listed above.

---

<div align="center">

**Zoraxy CrowdSec Bouncer** · part of the Self family · Teil der Self-Familie<br>
made with 🛡️ for self-hosting

</div>
