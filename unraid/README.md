# Unraid

Das Unraid-Template liegt im Repo [s3lfcod3r/unraid-templates](https://github.com/s3lfcod3r/unraid-templates/blob/main/templates/zoraxy-crowdsec-bouncer.xml) und wird von dort in Community Applications gelistet.
The Unraid template lives in [s3lfcod3r/unraid-templates](https://github.com/s3lfcod3r/unraid-templates/blob/main/templates/zoraxy-crowdsec-bouncer.xml) and is listed in Community Applications from there.

## Template manuell laden / Load the template manually

Unraid → **Docker** → **Add Container** → ganz unten **Template URL**:

```
https://raw.githubusercontent.com/s3lfcod3r/unraid-templates/main/templates/zoraxy-crowdsec-bouncer.xml
```

Dann **Load** klicken — alle Felder werden automatisch befüllt.
Then click **Load** — all fields are filled in automatically.

## Vorher lesen / Read first

CrowdSec ist **nicht** in diesem Image enthalten. Die vollständige Einrichtung (CrowdSec-Container, Log-Mount, `acquis.yaml`, Parser-Collection, Bouncer-API-Key) steht in der [Haupt-README](../README.md#crowdsec-auf-unraid-einrichten-voraussetzung).

CrowdSec is **not** bundled in this image. The full setup is documented in the [main README](../README.md#-english).
