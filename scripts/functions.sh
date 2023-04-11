#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source /backup/scripts/colors.sh

function checkEnvironemntVariable() {
    var="$1"
    eval value="\$${var}"

    if [ -z "$value" ]; then
        echo "You need to set the '$var' environment variable."
        exit 1
    fi
}

function checkAllEnvironemntVariables() {
    checkEnvironemntVariable "S3_ACCESS_KEY_ID"
    checkEnvironemntVariable "S3_SECRET_ACCESS_KEY"
    checkEnvironemntVariable "S3_BUCKET"
    checkEnvironemntVariable "POSTGRES_HOST"
    checkEnvironemntVariable "POSTGRES_USER"
    checkEnvironemntVariable "POSTGRES_PASSWORD"

    echo "Environment variables check finished without errors."
}

function printMsg() {
    if [ -z "$2" ]; then
        # No specific color informed, perform e regular echo
        echo "$1"

        return
    fi

    # shellcheck disable=SC2059
    printf "${2}${1}${COLOR_OFF}\n"
}

function printHeader() {
    termwidth="80"

    spacer=$(printf '=%.0s' $(seq 1 $termwidth))

    printMsg "$spacer" "${COLOR_BACKGROUND_BLUE}${COLOR_BOLD_WHITE}"

    padding="$(printf '%0.1s' ={1..500})"
    title=$(printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding")
    printMsg "$title" "${COLOR_BACKGROUND_BLUE}${COLOR_BOLD_WHITE}"

    printMsg "$spacer" "${COLOR_BACKGROUND_BLUE}${COLOR_BOLD_WHITE}"

    printMsg ""
}

function printTitle() {
    printMsg "======== $1 ========" "${COLOR_BACKGROUND_BLUE}${COLOR_BOLD_WHITE}"
}

function printSuccess() {
    printMsg "${1}" "${COLOR_BACKGROUND_GREEN}${COLOR_BOLD_WHITE}"
}

function printWarning() {
    printMsg "${1}" "${COLOR_BACKGROUND_YELLOW}${COLOR_BOLD_WHITE}"
}

function printFailure() {
    printMsg "${1}" "${COLOR_BACKGROUND_RED}${COLOR_BOLD_WHITE}"
}

function assertStringEquals() {
    if [[ "$1" == "$2" ]]; then
        printSuccess "Success asserting that string is '${2}'!"
    else
        printFailure "Failed asserting that string is '${2}' (actual value: '${1}')!"
        exit 1
    fi
}

function assertStringContains() {
    filteredLine=$(echo "${1}" | grep -s "${2}" || true)
    if [[ "$filteredLine" != "" ]]; then
        printSuccess "Success asserting that string contains '${2}'!"
    else
        printFailure "Failed asserting that string contains '${2}'!"
        exit 1
    fi
}

function assertStringEmpty() {
    if [[ "$1" == "" ]]; then
        printSuccess "Success asserting that string is empty!"
    else
        printFailure "Failed asserting that string is empty (actual value: '${1}')!"
        exit 1
    fi
}

function getQueryResponse() {
    export PGPASSWORD=$POSTGRES_PASSWORD
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
