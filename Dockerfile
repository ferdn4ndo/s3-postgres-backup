FROM alpine:3.17
LABEL maintaner="Fernando Constantino <const.fernando@gmail.com>"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="ferdn4ndo/s3-postgres-backup"
LABEL org.label-schema.description="A lightweight docker image to automatically perform periodic dumps of a Postgres server to an S3 bucket."
LABEL org.label-schema.vcs-url="https://github.com/ferdn4ndo/s3-postgres-backup"
LABEL org.label-schema.usage="/backup/README.md"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -d --rm --env-file ./.env ferdn4ndo/s3-postgres-backup"
LABEL org.label-schema.docker.cmd.devel="docker run --rm --env-file ./.env -v ./scripts:/backup/scripts ferdn4ndo/s3-postgres-backup"
LABEL org.label-schema.docker.cmd.test="docker run --rm --env-file ./.env ferdn4ndo/s3-postgres-backup tests.sh"

WORKDIR /backup

RUN apk update \
    && apk add -v bash \
    && apk add -v coreutils \
    && apk add -v postgresql-client \
    && apk add -v python3 py3-pip py3-six && pip install awscli && apk del py3-pip \
    && apk add -v openssl \
    && apk add -v curl \
    && apk add -v xz \
    && curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && chmod u+x /usr/local/bin/go-cron \
    && apk del curl \
    && apk update \
    && apk upgrade -f -v \
    && rm -rf /var/cache/apk/*

ADD entrypoint.sh entrypoint.sh

ADD scripts ./scripts

RUN chmod +x entrypoint.sh

ENTRYPOINT ["sh", "entrypoint.sh"]
