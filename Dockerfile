# Production-Ready Asterisk 22.5.2 on Debian 13.1
# Built: October 7, 2025
# Asterisk Version: 22.5.2 (asterisk-22-current)
# Purpose: Complete production-ready Asterisk service

FROM debian:13.1 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies including subversion for MP3
RUN apt-get update && apt-get install -y \
    autoconf automake bison build-essential curl flex \
    libasound2-dev libcurl4-openssl-dev libedit-dev \
    libgsm1-dev libjansson-dev libncurses5-dev libnewt-dev \
    libogg-dev libopus-dev libopusfile-dev libpopt-dev \
    libresample1-dev libspandsp-dev libspeex-dev \
    libspeexdsp-dev libsqlite3-dev libsrtp2-dev libssl-dev \
    libtool libvorbis-dev libxml2-dev libxslt1-dev \
    pkg-config portaudio19-dev unixodbc-dev uuid-dev \
    wget xmlstarlet \
    subversion \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libvpx-dev \
    x264 \
    libx264-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Download Asterisk 22.5.2
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz \
    && tar -xzf asterisk-22-current.tar.gz \
    && rm asterisk-22-current.tar.gz \
    && mv asterisk-22* asterisk

WORKDIR /usr/src/asterisk

# Install MP3 support
RUN contrib/scripts/get_mp3_source.sh

# Configure with bundled dependencies for compatibility
RUN ./configure \
    --with-jansson-bundled \
    --with-pjproject-bundled \
    --with-crypto \
    --with-ssl \
    --with-srtp

# In menuselect, enable video codecs
RUN make menuselect.makeopts \
    && menuselect/menuselect \
        --enable CORE-SOUNDS-EN-GSM \
        --enable MOH-OPSOUND-GSM \
        --enable EXTRA-SOUNDS-EN-GSM \
        --enable chan_pjsip \
        --enable res_pjsip \
        --enable codec_opus \
        --enable codec_g722 \
        --enable codec_g726 \
        --enable codec_gsm \
        --enable format_mp3 \
        --enable codec_h264 \
        --enable format_h264 \
        menuselect.makeopts

# Compile using all CPU cores
RUN make -j$(nproc)

# Install to system (without make config - not needed for Docker)
RUN make install \
    && make samples

# Update library cache
RUN ldconfig

# Verify installation
RUN /usr/sbin/asterisk -V
RUN test -d /etc/asterisk || exit 1
RUN test -f /etc/asterisk/asterisk.conf || exit 1
RUN test -f /usr/lib/libasteriskssl.so.1 || exit 1

# Runtime stage - Lean production image
FROM debian:13.1

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libasound2 \
    libcurl4 \
    libedit2 \
    libgsm1 \
    libjansson4 \
    libncurses6 \
    libnewt0.52 \
    libogg0 \
    libopus0 \
    libopusfile0 \
    libpopt0 \
    libresample1 \
    libspandsp2 \
    libspeex1 \
    libspeexdsp1 \
    libsqlite3-0 \
    libsrtp2-1 \
    libssl3 \
    libvorbis0a \
    libvorbisenc2 \
    libxml2 \
    libxslt1.1 \
    unixodbc \
    uuid \
    xmlstarlet \
    && rm -rf /var/lib/apt/lists/*

# Copy Asterisk installation from builder
COPY --from=builder /usr/sbin/asterisk /usr/sbin/
COPY --from=builder /usr/sbin/astgenkey /usr/sbin/
COPY --from=builder /usr/sbin/safe_asterisk /usr/sbin/
COPY --from=builder /usr/sbin/astcanary /usr/sbin/
COPY --from=builder /usr/lib/asterisk /usr/lib/asterisk
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /etc/asterisk /etc/asterisk

# Create runtime directories with proper permissions
RUN mkdir -p \
    /var/spool/asterisk \
    /var/log/asterisk \
    /var/run/asterisk \
    && chmod -R 750 \
    /var/spool/asterisk \
    /var/log/asterisk \
    /var/run/asterisk

# Register shared libraries
RUN ldconfig

# Expose SIP and RTP ports
# 5060: SIP signaling (UDP/TCP)
# 10000-20000: RTP media streams (UDP)
EXPOSE 5060/udp 5060/tcp
EXPOSE 10000-20000/udp

# Volumes for persistence (can be overridden in docker-compose)
VOLUME ["/etc/asterisk", "/var/lib/asterisk", "/var/log/asterisk", "/var/spool/asterisk"]

# Health check - verify Asterisk responds to CLI commands
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD asterisk -rx "core show version" || exit 1

# Run Asterisk in foreground (required for Docker)
# -f: foreground mode (don't daemonize)
# -vvvg: very verbose logging with colors for debugging
CMD ["/usr/sbin/asterisk", "-f", "-vvvg"]

