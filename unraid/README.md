# Unraid

Dieser Ordner enthält das **Container-Template** für Unraid.
This folder contains the **Unraid container template**.

| Datei / File | Zweck / Purpose |
|---|---|
| `zoraxy-crowdsec-bouncer.xml` | Container-Template (Ports, Pfade, Variablen) |

> Das Maintainer-Profil `ca_profile.xml` liegt bewusst im **Repo-Root** — so erwartet es Unraid Community Applications.
> The maintainer profile `ca_profile.xml` intentionally lives in the **repository root**, where Community Applications expects it.

## Template manuell laden / Load the template manually

Unraid → **Docker** → **Add Container** → ganz unten **Template URL**:

```
https://raw.githubusercontent.com/s3lfcod3r/zoraxy-crowdsec-bouncer/main/unraid/zoraxy-crowdsec-bouncer.xml
```

Dann **Load** klicken — alle Felder werden automatisch befüllt.
Then click **Load** — all fields are filled in automatically.

## Vorher lesen / Read first

CrowdSec ist **nicht** in diesem Image enthalten. Die vollständige Einrichtung (CrowdSec-Container, Log-Mount, `acquis.yaml`, Parser-Collection, Bouncer-API-Key) steht in der [Haupt-README](../README.md#crowdsec-auf-unraid-einrichten-voraussetzung).

CrowdSec is **not** bundled in this image. The full setup is documented in the [main README](../README.md#-english).
