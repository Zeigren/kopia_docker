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

ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$DATE \
    org.label-schema.vendor="Zeigren" \
    org.label-schema.name="zeigren/kopia" \
    org.label-schema.url="https://hub.docker.com/r/zeigren/kopia" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$URL \
    org.label-schema.vcs-branch=$BRANCH \
    org.label-schema.vcs-ref=$COMMIT

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /go/bin/kopia /app/kopia

COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR /app

EXPOSE 51515

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/app/kopia", "server", "start"]
