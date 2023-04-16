#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source ./asserts.sh

###
### UTs of the methods from the 'strings.sh' file
###

testPrintMsg() {
    printMsg "Testing the default printMsg method behavior"

    exec 5>&1
    output=$(printMsg "test")

    assertStringEquals "${output}" "test"
}

testPrintMsgWithColor() {
    printMsg "Testing the printMsg method behavior with a defined color"

    exec 5>&1
    output=$(printMsg "test" "${COLOR_RED}")

    # shellcheck disable=SC2001
    output=$(echo "${output}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

    assertStringEquals "${output}" "test"
}

testPrintTitle() {
    printMsg "Testing the printTitle method"

    exec 5>&1
    output=$(printTitle "test")

    # shellcheck disable=SC2001
    output=$(echo "${output}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

    assertStringContains "${output}" "= test ="
}

testPrintHeader() {
    printMsg "Testing the printHeader method"

    exec 5>&1
    output=$(printHeader "test")

    # shellcheck disable=SC2001
    output=$(echo "${output}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

    assertStringContains "${output}" "= test ="

    termwidth=80
    spacer=$(printf '=%.0s' $(seq 1 $termwidth))
    assertStringContains "${output}" "${spacer}"
}

testPrintHeaderLong() {
    printMsg "Testing the printHeader method with a very long title"

    longMsg="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed et ipsum molestie justo."

    exec 5>&1
    output=$(printHeader "${longMsg}")

    # shellcheck disable=SC2001
    output=$(echo "${output}" | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')

    assertStringContains "${output}" "${longMsg}"

    termwidth=80
    spacer=$(printf '=%.0s' $(seq 1 $termwidth))
    assertStringContains "${output}" "${spacer}"
}

if [ -z "$1" ]; then
    printWarning "No argument supplied, running all the tests in the file!"

    testPrintMsg
    testPrintMsgWithColor
    testPrintTitle
    testPrintHeader
    testPrintHeaderLong
else
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testPrintMsg' ]] && ( testPrintMsg )
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testPrintMsgWithColor' ]] && ( testPrintMsgWithColor )
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testPrintHeader' ]] && ( testPrintHeader )
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testPrintHeaderLong' ]] && ( testPrintHeaderLong )
fi

printSuccess "ALL TESTS PASSED!"
