FROM node:22-bookworm AS base

RUN groupadd lightweb

COPY docker/init-users.sh /usr/local/bin/init-users.sh
RUN chmod +x /usr/local/bin/init-users.sh

WORKDIR /app

# --- Dev target ---
FROM base AS dev

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/init-users.sh"]
CMD ["tail", "-f", "/dev/null"]
