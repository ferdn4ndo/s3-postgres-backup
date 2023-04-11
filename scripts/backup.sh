#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source /backup/scripts/functions.sh

printTitle "Database Backup Creation"

########################################################
## Environment check section
########################################################
checkAllEnvironemntVariables

AWS_ARGS="$(getAwsCliArgs)"

########################################################
## Environment setup section
########################################################
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

# prepare temp folder
mkdir -p "${TEMP_PATH}"

########################################################
## Temp folder cleanup
########################################################
echo "Removing previous temp files (TEMP_PATH: ${TEMP_PATH})..."
rm -rfv "${TEMP_PATH}"/*.*

########################################################
## Dump section
########################################################
DEST_FILE="$(date +"%Y-%m-%dT%H-%M-%SZ").sql"
if [ -n "${BACKUP_PREFIX}" ]; then
    DEST_FILE="${BACKUP_PREFIX}_${DEST_FILE}"
fi
LOCAL_FILE="${TEMP_PATH}/${DEST_FILE}"
if [ "${POSTGRES_DATABASE}" != "" ]; then
    printMsg "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST} (saving to ${LOCAL_FILE})..."
    # shellcheck disable=SC2086
    pg_dump $POSTGRES_HOST_OPTS "$POSTGRES_DATABASE" > "$LOCAL_FILE"
else
    printMsg "Creating dump of all databases from ${POSTGRES_HOST} (saving to ${LOCAL_FILE})..."
    # shellcheck disable=SC2086
    pg_dumpall $POSTGRES_HOST_OPTS > "$LOCAL_FILE"
fi
printMsg "Created dump file ${LOCAL_FILE}"

########################################################
## Compression section
########################################################
if [ "${XZ_COMPRESSION_LEVEL}" = "0" ] || [ "${SKIP_COMPRESSION}" = "1" ]; then
    printMsg "Skipping compression"
else
    printMsg "Compressing file..."
    if [ "${XZ_COMPRESSION_LEVEL}" = "" ]; then
        XZ_COMPRESSION_LEVEL=6
    fi
    # shellcheck disable=SC2086
    xz --compress -${XZ_COMPRESSION_LEVEL} "${LOCAL_FILE}"
    ZIP_FILE="${LOCAL_FILE}.xz"
    DEST_FILE="${DEST_FILE}.xz"
    if [ ! -f "$ZIP_FILE" ]; then
        printFailure "ERROR: File $ZIP_FILE should exist by now."
        exit 1;
    fi
    LOCAL_FILE="$ZIP_FILE"
    printMsg "Created compressed file ${LOCAL_FILE}"
fi

########################################################
## Encryption section
########################################################
if [ "${ENCRYPTION_PASSWORD}" != "" ]; then
    printMsg "Encrypting..."
    ENC_FILE="${LOCAL_FILE}.enc"
    if ! openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in "${LOCAL_FILE}" -out "${ENC_FILE}" -k "${ENCRYPTION_PASSWORD}"; then
        printFailure "Error encrypting ${ENC_FILE}"
        exit 1;
    fi
    rm "${LOCAL_FILE}"
    LOCAL_FILE="${ENC_FILE}"
    DEST_FILE="${DEST_FILE}.enc"
    printMsg "Created encrypted file ${DEST_FILE}"
fi

########################################################
## Upload section
########################################################
S3_FULL_PATH=$(getS3FullPath "${DEST_FILE}")
echo "Uploading dump to bucket '$S3_BUCKET' (full path: ${S3_FULL_PATH})"
# shellcheck disable=SC2086
UPLOAD_RESULT=$(aws $AWS_ARGS s3 cp - "$S3_FULL_PATH" < "${LOCAL_FILE}")
echo "Upload result: ${UPLOAD_RESULT}"
echo "Upload complete! File was uploaded to: ${S3_FULL_PATH}"
echo "Removing temp file..."
rm "${LOCAL_FILE}"

########################################################
## Legacy backup cleanup section
########################################################
if [ "${DELETE_OLDER_THAN}" != "" ]; then
    printMsg "Checking for files older than ${DELETE_OLDER_THAN}"
    rootPath=$(getS3FullPath)
    # shellcheck disable=SC2086
    aws $AWS_ARGS s3 ls "${rootPath}/" | grep " PRE " -v | while read -r line; do
        # shellcheck disable=SC1083
        fileName=$(echo "$line"|awk {'print $4'})
        # shellcheck disable=SC1083
        created=$(echo "$line"|awk {'print $1" "$2'})
        created=$(date -d "$created" +%s)
        older_than=$(date -d "$DELETE_OLDER_THAN" +%s)
        if [ "$created" -lt "$older_than" ]; then
            if [ "$fileName" != "" ]; then
                printMsg "DELETING ${fileName}"
                fullFilePath=$(getS3FullPath ${fileName})
                aws $AWS_ARGS s3 rm "${fullFilePath}"
            fi
        else
            printWarning "${fileName} skipped as it's not older than ${DELETE_OLDER_THAN}"
        fi
    done;
fi

########################################################
## END
########################################################
printSuccess "Database backup completed!"
