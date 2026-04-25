# Stage 1: Build Obscura from source
FROM rust:1.75-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    clang \
    python3 \
    ninja-build \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/obscura
COPY . .

# Build both binaries with stealth feature
RUN cargo build --release --features stealth

# Stage 2: Runtime
FROM debian:bookworm-slim

# Install runtime dependencies and socat (to bind to 0.0.0.0)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    socat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /usr/src/obscura/target/release/obscura /usr/local/bin/obscura
COPY --from=builder /usr/src/obscura/target/release/obscura-worker /usr/local/bin/obscura-worker

# Expose the default CDP port
EXPOSE 9222

# Script to run obscura on 127.0.0.1 and use socat to bind to 0.0.0.0
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables to configure the entrypoint
ENV PORT=9222
ENV WORKERS=1
ENV STEALTH=true

ENTRYPOINT ["docker-entrypoint.sh"]
