#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source ./asserts.sh
# shellcheck disable=SC1091
source ./strings.sh

function checkAllEnvironmentVariables() {
    assertEnvironmentVariableNotEmpty "SCHEDULE"

    assertEnvironmentVariableNotEmptyOrDefault "S3_REGION" "<region>"
    assertEnvironmentVariableNotEmptyOrDefault "S3_BUCKET" "<bucket>"
    assertEnvironmentVariableNotEmptyOrDefault "S3_ACCESS_KEY_ID" "<key_id>"
    assertEnvironmentVariableNotEmptyOrDefault "S3_SECRET_ACCESS_KEY" "<access_key>"

    assertEnvironmentVariableNotEmptyOrDefault "POSTGRES_HOST" "<host>"
    assertEnvironmentVariableNotEmptyOrDefault "POSTGRES_USER" "<user>"
    assertEnvironmentVariableNotEmptyOrDefault "POSTGRES_PASSWORD" "<password>"

    echo "Environment variables check finished without errors."
}

function getQueryResponse() {
    export PGPASSWORD=$POSTGRES_PASSWORD

    POSTGRES_PORT="${POSTGRES_PORT:-5432}"

    # shellcheck disable=SC2153
    POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

    database="${1}"
    query="${2}"

    # Get the query response from Postgres
    # shellcheck disable=SC2086
    response=$(psql $POSTGRES_HOST_OPTS -d "${database}" -AXqtc "${query}")

    # Clear anything but the first line of the response
    response=$(echo "${response}" | head -1)

    echo "${response}"
}

function getDatabaseTablesCount() {
    # Retrieves only the 'custom' tables count inside a given database ($1)
    getQueryResponse "${POSTGRES_DB}" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','pg_catalog');"
}

function getAwsCliArgs() {
    AWS_ARGS=""

    if [[ "${S3_ENDPOINT}" != "" ]]; then
        AWS_ARGS="${AWS_ARGS} --endpoint-url ${S3_ENDPOINT}"
    fi

    if [[ "${S3_EXTRA_OPTS}" != "" ]]; then
        AWS_ARGS="${AWS_ARGS} ${S3_EXTRA_OPTS}"
    fi

    echo "$AWS_ARGS"
}

function getS3FullPath() {
    fullPath="s3://${S3_BUCKET}"

    if [[ "${S3_PREFIX}" != "" ]]; then
        fullPath="${fullPath}/${S3_PREFIX}"
    fi

    if [[ "${1}" != "" ]]; then
        fullPath="${fullPath}/${1}"
    fi

    echo "${fullPath}"
}
