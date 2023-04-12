#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source /backup/scripts/functions.sh

printTitle "Database Backup Restoration"

########################################################
## Environment setup section
########################################################
TEMP_PATH="${TEMP_PATH:-/temp}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

AWS_ARGS="$(getAwsCliArgs)"
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD
# shellcheck disable=SC2153
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

# prepare temp folder
mkdir -p "${TEMP_PATH}"

########################################################
## Listing backup files for restore section
########################################################

if [ $# -eq 0 ]; then
    printWarning "No backup file specified, listing possible values"

    rootPath=$(getS3FullPath)

    # shellcheck disable=SC2086
    aws $AWS_ARGS s3 ls "${rootPath}/" | grep " PRE " -v | while read -r line;
    do
        # shellcheck disable=SC1083
        fileName=$(echo "$line" | awk {'print $4'})
        # shellcheck disable=SC1083
        created=$(echo "$line" | awk {'print $1" "$2'})

        printMsg "FILE [${created}]: ${fileName}"
    done;

    printMsg ""
    printMsg ""
    printMsg "Run this command again passing the filename as parameter, like:"
    printMsg ""
    printMsg "${0##*/} postgres-dump-all_2020-07-04T05:54:33Z.sql.gz.enc"
    printMsg ""

    exit 0;
fi

########################################################
## Download file
########################################################
REMOTE_FILE="$1"
remoteFilePath=$(getS3FullPath "${REMOTE_FILE}")

printMsg "Trying to download file ${REMOTE_FILE} from ${remoteFilePath}"

LOCAL_FILE="${TEMP_PATH}/${REMOTE_FILE}"
# shellcheck disable=SC2086
aws $AWS_ARGS s3 cp "${remoteFilePath}" "${LOCAL_FILE}"
printMsg "Downloaded file to ${LOCAL_FILE}"

########################################################
## Decryption
########################################################
FILE_EXT=${LOCAL_FILE##*.}
if [ "${FILE_EXT}" = "enc" ]; then
    printMsg "Decrypting file..."
    DECRYPTED_FILE=${LOCAL_FILE%.*}
    openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in "${LOCAL_FILE}" -out "${DECRYPTED_FILE}" -k "${ENCRYPTION_PASSWORD}"
    rm "$LOCAL_FILE"
    LOCAL_FILE="${DECRYPTED_FILE}"
    printMsg "Decrypted file to ${LOCAL_FILE}"
fi

########################################################
## Decompression
########################################################
FILE_EXT=${LOCAL_FILE##*.}
if [ "${FILE_EXT}" = "xz" ]; then
    printMsg "Decompressing file..."
    DECOMPRESSED_FILE=${LOCAL_FILE%.*}
    xz --decompress --force "${LOCAL_FILE}"
    LOCAL_FILE="${DECOMPRESSED_FILE}"
    printMsg "Decompressed file to ${LOCAL_FILE}"
fi

########################################################
## Import
########################################################
if [ ! -f "$LOCAL_FILE" ]; then
    printFailure "ERROR: File $LOCAL_FILE should exist by now."
    exit 1;
fi
FILE_EXT=${LOCAL_FILE##*.}
if [ "${FILE_EXT}" != "sql" ]; then
    printFailure "Local file '${FILE_EXT}' should have .sql extension now!"
    exit 1;
fi

printMsg "Importing dump..."
# shellcheck disable=SC2086
psql $POSTGRES_HOST_OPTS -f "$LOCAL_FILE" > /dev/null
printMsg "Restore complete!"

printMsg "Removing temp file..."
rm "${LOCAL_FILE}"

########################################################
## END
########################################################
printSuccess "Database restore completed!"
