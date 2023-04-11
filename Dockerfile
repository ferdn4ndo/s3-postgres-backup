FROM alpine:3.17
LABEL maintaner="Fernando Constantino <const.fernando@gmail.com>"

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
