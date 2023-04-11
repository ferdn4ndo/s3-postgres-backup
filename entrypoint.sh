#!/bin/sh

set -e

cd /backup/scripts

if [ "${S3_S3V4}" = "yes" ]; then
  echo "Configuring S3V4 Signature"
  aws configure set default.s3.signature_version s3v4
fi

if [ "${SCHEDULE}" = "**None**" ]; then
  echo "No schedule defined, backing up now!"
  sh backup.sh
else
  if [ "${RUN_AT_STARTUP}" = "1" ]; then
    echo "Waiting ${STARTUP_BKP_DELAY_SECS} seconds as the startup delay"
    sleep "${STARTUP_BKP_DELAY_SECS}"
    sh backup.sh
  fi
  echo "Creating cron..."
  exec go-cron "$SCHEDULE" /bin/sh backup.sh
fi
