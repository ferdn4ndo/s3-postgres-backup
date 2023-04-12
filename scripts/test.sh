#!/bin/bash

set -e
set -o pipefail

# shellcheck disable=SC1091
source /backup/scripts/functions.sh

POSTGRES_DB="test"

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
# shellcheck disable=SC2153
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

printHeader "Test Suite for s3-postgres-backup"

printTitle "Populating dataset"
# shellcheck disable=SC2086
psql $POSTGRES_HOST_OPTS <<EOF
    -- Drop the database if already exists and create a new one
    DROP DATABASE IF EXISTS ${POSTGRES_DB};
    CREATE DATABASE ${POSTGRES_DB};

    -- Use the database
    \c ${POSTGRES_DB}

    -- Create table1
    CREATE TABLE table1 (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50),
        age INTEGER
    );

    -- Insert some sample records into table1
    INSERT INTO table1 (name, age) VALUES
        ('John', 30),
        ('Jane', 25),
        ('Bob', 40);

    -- Create table2
    CREATE TABLE table2 (
        id SERIAL PRIMARY KEY,
        city VARCHAR(50),
        country VARCHAR(50)
    );

    -- Insert some sample records into table2
    INSERT INTO table2 (city, country) VALUES
        ('New York', 'USA'),
        ('London', 'UK'),
        ('Tokyo', 'Japan');
\gexec
EOF

printTitle "Checking dataset integrity before backup"

printMsg "Checking database tables count (expecting 2)"
tablesCount=$(getDatabaseTablesCount "${POSTGRES_DB}")
assertStringEquals "$tablesCount" "2"

printMsg "Checking the age value for John (expecting 30)"
response=$(getQueryResponse "${POSTGRES_DB}" "SELECT age FROM table1 WHERE name = 'John';")
assertStringEquals "$response" "30"

printMsg "Checking the country value for London (expecting UK)"
response=$(getQueryResponse "${POSTGRES_DB}" "SELECT country FROM table2 WHERE city = 'London';")
assertStringEquals "$response" "UK"

printMsg "Performing backup operation"
backupResponse=$(/backup/scripts/backup.sh)
printMsg "Backup operation response:"
printMsg "${backupResponse}"
printMsg "Asserting that the final upload operation was successful"
assertStringContains "${backupResponse}" "Upload complete!"

printMsg "Parsing uploaded filename from backup operation"
backupFilenameLine=$(echo "${backupResponse}" | grep -s "Upload complete!")
backupFilename=$(echo "${backupFilenameLine}" | sed "s/.*\///")
printMsg "Parsed filename: $backupFilename"

printTitle "Cleaning dataset"
# shellcheck disable=SC2086
psql $POSTGRES_HOST_OPTS <<EOF
    DROP DATABASE IF EXISTS ${POSTGRES_DB};
    CREATE DATABASE ${POSTGRES_DB};
\gexec
EOF

printMsg "Checking database tables count (expecting '0' as the database was cleaned)"
tablesCount=$(getDatabaseTablesCount "${POSTGRES_DB}")
assertStringEquals "${tablesCount}" "0"

printMsg "Performing restore operation"
restoreResponse=$(/backup/scripts/restore.sh "${backupFilename}")
printMsg "Restore operation response:"
printMsg "${restoreResponse}"
printMsg "Asserting that the final restore operation was successful"
assertStringContains "${restoreResponse}" "Database restore completed!"

printTitle "Checking dataset integrity after restoration"

printMsg "Checking database tables count (expecting 2)"
tablesCount=$(getDatabaseTablesCount "${POSTGRES_DB}")
assertStringEquals "${tablesCount}" "2"

printMsg "Checking the age value for John (expecting 30)"
response=$(getQueryResponse "${POSTGRES_DB}" "SELECT age FROM table1 WHERE name = 'John';")
assertStringEquals "${response}" "30"

printMsg "Checking the country value for London (expecting UK)"
response=$(getQueryResponse "${POSTGRES_DB}" "SELECT country FROM table2 WHERE city = 'London';")
assertStringEquals "${response}" "UK"

printTitle "Excluding test backup file from S3"
printMsg "Backup filename: ${backupFilename}"
fullFilePath=$(getS3FullPath "${backupFilename}")
printMsg "Backup file path: ${fullFilePath}"

printMsg "Asserting that the file ${fullFilePath} exists"
# shellcheck disable=SC2086
fileExistsResponse=$(aws ${AWS_ARGS} s3 ls "${fullFilePath}")
assertStringContains "${fileExistsResponse}" "${backupFilename}"

printMsg "Removing file from ${fullFilePath}"
# shellcheck disable=SC2086
aws $AWS_ARGS s3 rm "${fullFilePath}"

printMsg "Asserting that the file ${fullFilePath} was removed"
# shellcheck disable=SC2086
fileExistsResponse=$(aws ${AWS_ARGS} s3 ls "${fullFilePath}" || true)
assertStringEmpty "${fileExistsResponse}" ""

printMsg ""
printSuccess "ALL TESTS PASSED!"
