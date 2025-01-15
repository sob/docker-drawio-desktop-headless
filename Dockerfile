# Stage 1: Download draw.io
FROM docker.io/library/debian:sid-20250113-slim AS downloader
LABEL stage=builder
ARG TARGETARCH
ARG DRAWIO_VERSION

WORKDIR /downloads

RUN set -ex \
    && echo "Architecture: ${TARGETARCH}" \
    && echo "Draw.io version: ${DRAWIO_VERSION}" \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget ca-certificates \
    && DOWNLOAD_URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    && echo "Downloading from: ${DOWNLOAD_URL}" \
    && wget --verbose "${DOWNLOAD_URL}" \
    && ls -la \
    && if [ ! -f "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" ]; then \
        echo "Failed to download Draw.io for architecture ${TARGETARCH}"; \
        exit 1; \
    fi

# Final stage
FROM docker.io/library/debian:sid-20250113-slim
ARG TARGETARCH
ARG BUILD_DATE
ARG VCS_REF
ARG DRAWIO_VERSION

# Add labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/sob/docker-drawio-desktop-headless" \
      maintainer="sob" \
      description="Draw.io Desktop in headless mode" \
      version="${DRAWIO_VERSION}" \
      stage=final

WORKDIR "/opt/drawio-desktop"

# Copy draw.io from downloader stage
COPY --from=downloader /downloads/drawio-*.deb ./

# Install dependencies and draw.io
RUN set -e \
    && echo "selected arch: ${TARGETARCH}" \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xvfb \
        libgbm1 \
        libasound2t64 \
        fonts-liberation \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-noto \
        fonts-noto-cjk \
        fonts-ipafont-mincho \
        fonts-ipafont-gothic \
        fonts-unfonts-core \
        fonts-montserrat \
    && apt-get install -y "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    && rm -f "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    # Setup directories and permissions
    && mkdir -p /data/home/.config/draw.io-desktop \
                /data/home/.config/electron \
                /data/home/.cache \
                /opt/drawio/resources/app.asar.unpacked/userData \
    # Additional cleanup
    && rm -rf /usr/share/doc/* \
              /usr/share/man/* \
              /usr/share/locale/* \
              /var/cache/apt/* \
              /var/lib/apt/lists/* \
              /tmp/* \
    && find /var/log -type f -delete \
    && chmod a+w .

# Set environment variables
ENV DRAWIO_DESKTOP_EXECUTABLE_PATH="/opt/drawio/drawio" \
    DRAWIO_DESKTOP_SOURCE_FOLDER="/opt/drawio-desktop" \
    DRAWIO_DESKTOP_RUNNER_COMMAND_LINE="/opt/drawio-desktop/runner.sh" \
    DRAWIO_DESKTOP_COMMAND_TIMEOUT="10s" \
    DRAWIO_DISABLE_UPDATE="true" \
    XVFB_DISPLAY=":42" \
    XVFB_OPTIONS="-nolisten unix" \
    ELECTRON_DISABLE_SECURITY_WARNINGS="true" \
    ELECTRON_ENABLE_LOGGING="false" \
    ELECTRON_USER_DATA_DIR="/data/home/.config/electron"

# Copy application files
COPY --chmod=755 src/* ./

ENTRYPOINT ["/opt/drawio-desktop/entrypoint.sh"]
CMD ["--help"]
