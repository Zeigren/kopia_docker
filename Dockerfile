FROM golang:latest AS build
# https://github.com/kopia/kopia/blob/master/BUILD.md
ARG VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ \
    gcc \
    libc6-dev \
    make \
    pkg-config \
    git \
    curl
RUN git clone -b $VERSION --depth 1 https://github.com/kopia/kopia.git
RUN cd ./kopia && make install


FROM ubuntu:latest AS production

ARG DATE
ARG VERSION

LABEL org.opencontainers.image.created=$DATE \
    org.opencontainers.image.authors="Zeigren" \
    org.opencontainers.image.url="https://github.com/Zeigren/kopia_docker" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.title="zeigren/kopia" \
    org.opencontainers.image.source="https://github.com/Zeigren/kopia_docker"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /go/bin/kopia /usr/bin/kopia

COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR /app

EXPOSE 51515

ENTRYPOINT ["/docker-entrypoint.sh"]
