#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source /backup/scripts/colors.sh

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

function assertStringDifferent() {
    if [[ "$1" != "$2" ]]; then
        printSuccess "Success asserting that string '${1}' is different than '${2}'!"
    else
        printFailure "Failed asserting that string is different than '${1}'!"
        exit 1
    fi
}
