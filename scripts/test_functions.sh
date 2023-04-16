#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source ./asserts.sh
source ./functions.sh

###
### The UTs of the custom service methods (in functions.sh) will go here
###

testGetAwsCliArgs() {
    printMsg "Testing the getAwsCliArgs method"

    previousS3Endpoint="${S3_ENDPOINT}"
    previousS3ExtraOpts="${S3_EXTRA_OPTS}"

    S3_ENDPOINT="testEndpoint"
    S3_EXTRA_OPTS="--testExtraOpts"

    exec 5>&1
    output=$(getAwsCliArgs)

    expectedOutput=" --endpoint-url testEndpoint --testExtraOpts"

    assertStringEquals "${output}" "${expectedOutput}"

    printMsg "Restoring previous env values"

    S3_ENDPOINT="${previousS3Endpoint}"
    S3_EXTRA_OPTS="${previousS3ExtraOpts}"
}

testGetS3FullPath() {
    printMsg "Testing the getS3FullPath method"

    previousS3Bucket="${S3_BUCKET}"
    previousS3Prefix="${S3_PREFIX}"

    S3_BUCKET="testBucket"
    S3_PREFIX="testPrefix"

    exec 5>&1
    output=$(getS3FullPath "testPath")

    expectedOutput="s3://${S3_BUCKET}/${S3_PREFIX}/testPath"

    assertStringEquals "${output}" "${expectedOutput}"

    printMsg "Restoring previous env values"

    S3_BUCKET="${previousS3Bucket}"
    S3_PREFIX="${previousS3Prefix}"
}

if [ -z "$1" ]; then
    printWarning "No argument supplied, running all the tests in the file!"

    testGetAwsCliArgs
    testGetS3FullPath
else
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testGetAwsCliArgs' ]] && ( testGetAwsCliArgs )
    # shellcheck disable=SC2199
    [[ "$@" =~ 'testGetS3FullPath' ]] && ( testGetS3FullPath )
fi

printSuccess "ALL TESTS PASSED!"
