# Versionen – werden automatisch durch auto-update.yml aktualisiert
ARG ZORAXY_VERSION=v3.3.5-rc4
ARG PLUGIN_VERSION=v1.2.3

# Plugin in einer Hilfsstufe holen: das Zoraxy-Image entfernt apk aus seinem
# finalen Image, dort lässt sich nichts mehr nachinstallieren.
FROM alpine:3.24 AS plugin
ARG PLUGIN_VERSION
ARG TARGETARCH=amd64
RUN apk add --no-cache git ca-certificates

# Plugin-Quellen (nicht ins Volume – werden beim Start kopiert)
RUN git clone --depth 1 --branch ${PLUGIN_VERSION} \
    https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer.git \
    /plugin/zoraxycrowdsecbouncer \
 && rm -rf /plugin/zoraxycrowdsecbouncer/.git

# Vorkompilierte Binary (seit v1.2.2 je Architektur benannt) samt Prüfsumme
RUN cd /plugin/zoraxycrowdsecbouncer \
 && BIN=zoraxycrowdsecbouncer_linux_${TARGETARCH} \
 && URL=https://github.com/AnthonyMichaelTDM/zoraxy_crowdsec_bouncer/releases/download/${PLUGIN_VERSION} \
 && wget -q "$URL/$BIN" "$URL/$BIN.sha256" \
 && sha256sum -c "$BIN.sha256" \
 && mv "$BIN" zoraxycrowdsecbouncer \
 && rm "$BIN.sha256" \
 && chmod +x zoraxycrowdsecbouncer

FROM zoraxydocker/zoraxy:${ZORAXY_VERSION}

COPY --from=plugin /plugin/zoraxycrowdsecbouncer /opt/zoraxy/plugin_bundled/zoraxycrowdsecbouncer

# Entrypoint kopieren
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Umgebungsvariablen
ENV CROWDSEC_API_KEY=""
ENV CROWDSEC_AGENT_URL="http://crowdsec:8080"
ENV CROWDSEC_LOG_LEVEL="warning"
ENV CROWDSEC_CLOUDFLARE="false"

ENTRYPOINT ["/entrypoint.sh"]
