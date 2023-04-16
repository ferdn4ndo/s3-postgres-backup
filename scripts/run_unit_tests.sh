#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source ./functions.sh

printMsg "Searching for executable test files..."

TEST_FILES_COUNTER=0
for testFile in test_*.sh; do
    printMsg "Executing test file '$testFile'"
    sh "${testFile}"
    TEST_FILES_COUNTER=$((TEST_FILES_COUNTER+1))
done

printMsg ""
printSuccess "SUCCESSFULLY EXECUTED ${TEST_FILES_COUNTER} TEST FILES!"
