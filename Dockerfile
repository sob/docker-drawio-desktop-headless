FROM docker.io/library/debian:sid-20250113-slim
ARG TARGETARCH
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/sob/docker-drawio-desktop-headless"

# Add labels for better container metadata
LABEL maintainer="sob" \
      description="Draw.io Desktop in headless mode" \
      version="25.0.2"

WORKDIR "/opt/drawio-desktop"

# Combine RUN commands to reduce layers and use proper cleanup in the same layer
RUN set -e \
    && echo "selected arch: ${TARGETARCH}" \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xvfb \
        wget \
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
    && apt-get clean \
    # Draw.io installation
    && DRAWIO_VERSION="25.0.2" \
    && wget -q "https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    && if [ ! -f "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" ]; then \
      echo "Failed to download Draw.io for architecture ${TARGETARCH}"; \
      exit 1; \
    fi \
    && apt-get install -y "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    && rm -f "./drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
    # Cleanup
    && apt-get remove -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && chmod a+w .

# Group related environment variables
ENV DRAWIO_DESKTOP_EXECUTABLE_PATH="/opt/drawio/drawio" \
    DRAWIO_DESKTOP_SOURCE_FOLDER="/opt/drawio-desktop" \
    DRAWIO_DESKTOP_RUNNER_COMMAND_LINE="/opt/drawio-desktop/runner.sh" \
    DRAWIO_DESKTOP_COMMAND_TIMEOUT="10s" \
    DRAWIO_DISABLE_UPDATE="true"

ENV XVFB_DISPLAY=":42" \
    XVFB_OPTIONS="-nolisten unix"

ENV ELECTRON_DISABLE_SECURITY_WARNINGS="true" \
    ELECTRON_ENABLE_LOGGING="false"

RUN mkdir -p /data/home/.config/draw.io-desktop \
    && mkdir -p /data/home/.config/electron \
    && mkdir -p /data/home/.cache \
    && chmod -R 777 /data \
    && chmod -R 777 /opt/drawio-desktop \
    && chmod -R 777 /opt/drawio \
    # Create electron userData directory with proper permissions
    && mkdir -p /opt/drawio/resources/app.asar.unpacked/userData \
    && chmod -R 777 /opt/drawio/resources

# Copy files at the end to leverage build cache
COPY --chmod=755 src/* ./

ENTRYPOINT ["/opt/drawio-desktop/entrypoint.sh"]
CMD ["--help"]
