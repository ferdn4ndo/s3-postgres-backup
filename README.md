# S3 Postgres Backup

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/ferdn4ndo/s3-postgres-backup/latest)](https://hub.docker.com/r/ferdn4ndo/s3-postgres-backup)
[![E2E test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_e2e.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![GitLeaks test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_code_leaks.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![Grype test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_grype_scan.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![ShellCheck test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_code_quality.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![Release](https://img.shields.io/github/v/release/ferdn4ndo/s3-postgres-backup)](https://github.com/ferdn4ndo/s3-postgres-backup/releases)
[![MIT license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)

An Alpine-based docker image to automatically perform periodic dumps of a Postgres server to an S3 bucket. Supports encryption, compression, and restoration. Protected against code leakage by [GitLeaks](https://github.com/gitleaks/gitleaks-action/) and package vulnerabilities by [Anchore Grype](https://github.com/anchore/grype). CI pipeline with code quality check by [Shellcheck](https://github.com/koalaman/shellcheck) and internal E2E Automated Tests (ATs).

## Main features

* Supports setting up a custom interval for the backup generation;
* Supports encryption (AES-256-CBC) using an environment variable password;
* Supports dump file compression (before encryption) using `xz` with a customizable level;
* Allows deleting previous backup files older than a customizable interval;
* Supports backup restoration using the CLI;
* Can create the dump for only one database or every database in the Postgres server;

## Summary

* [Main Features](#main-features)
* [Summary](#summary) *(you're here)*
* [How to Run?](#how-to-run)
  * [Requirements](#requirements)
  * [Preparing the environment](#preparing-the-environment)
  * [Building the image](#building-the-image)
* [Configuring](#configuring)
  * [General Configuration](#general-configuration)
    * [SCHEDULE](#schedule)
    * [ENCRYPTION_PASSWORD](#encryption_password)
    * [DELETE_OLDER_THAN](#delete_older_than)
    * [TEMP_PATH](#temp_path)
    * [XZ_COMPRESSION_LEVEL](#xz_compression_level)
    * [BACKUP_PREFIX](#backup_prefix)
    * [RUN_AT_STARTUP](#run_at_startup)
    * [STARTUP_BKP_DELAY_SECS](#startup_bkp_delay_secs)
  * [Postgres Configuration](#postgres-configuration)
    * [POSTGRES_DATABASE](#postgres_database)
    * [POSTGRES_HOST](#postgres_host)
    * [POSTGRES_PORT](#postgres_port)
    * [POSTGRES_USER](#postgres_user)
    * [POSTGRES_PASSWORD](#postgres_password)
    * [POSTGRES_EXTRA_OPTS](#postgres_extra_opts)
  * [AWS S3 Configuration](#aws-s3-configuration)
    * [S3_REGION](#s3_region)
    * [S3_BUCKET](#s3_bucket)
    * [S3_ACCESS_KEY_ID](#s3_access_key_id)
    * [S3_SECRET_ACCESS_KEY](#s3_secret_access_key)
    * [S3_PREFIX](#s3_prefix)
    * [S3_ENDPOINT](#s3_endpoint)
* [Testing](#testing)
* [Contributing](#contributing)
  * [Contributors](#contributors)
* [License](#license)

### Requirements

To run this service, make sure to comply with the following requirements:

1. There is an instance of Postgres up and running, from where the data will be exported;

2. There is an S3 bucket and an IAM user (identified by an ID and Key) to where the backup files will be uploaded;

3. Docker is installed and running in the host machine;

### Preparing the environment

First of all, clone the `.env.template` file to `.env` in the project root folder:

```bash
cp .env.template .env
```

Then edit the file accordingly.

### Building the image

To build the image (assuming the `s3-postgres-backup` image name and the `latest` tag) use the following command in the project root folder:

```bash
docker build -f ./Dockerfile --tag s3-postgres-backup:latest
```

After setting up the environment and building the image, you can now launch a container with it. Considering the 000, use the following command in the project root folder:

```bash
docker run -rm  -v "./backup/scripts:/backup/scripts" -v ./backup/temp:/backup/temp --env-file ./.env --name "s3-postgres-backup"  s3-postgres-backup:latest
```

## Configuring

The service is configured using environment variables. They are listed and described below. Use the Summary for faster navigation.

Note that default values suffixed by ¹ mean that they are invalid and must be replaced before running the service, otherwise an error will be thrown during startup.

### General Configuration

#### **SCHEDULE**

Main backup routine schedule. Uses the [CRON Expression Format](https://pkg.go.dev/github.com/robfig/cron#hdr-CRON_Expression_Format) and the default value is specifically of the [Interval](https://pkg.go.dev/github.com/robfig/cron#hdr-Intervals) type.

Required: **YES**

Default: `@every 6h`

#### **ENCRYPTION_PASSWORD**

The encryption password is used to encrypt the backup. If the value is empty, the backup won't be encrypted.

Required: **NO**

Default: *EMPTY*

#### **DELETE_OLDER_THAN**

If a DateTime in ISO format is specified, the backup system will delete backups that are older than the specified DateTime. When empty, no previous backup will be deleted.

Required: **NO**

Default: *EMPTY*

#### **TEMP_PATH**

The path that is used to temporarily store the exported dump file, compress and encrypt (if set), and upload to S3.

Required: **NO**

Default: `/temp`

#### **XZ_COMPRESSION_LEVEL**

Dump file compression level from `0` to `9`. Compression will be skipped with the values `0` and `1`.

Required: **NO**

Default: `6`

#### **BACKUP_PREFIX**

Optional prefix to be prepended to the backup filenames.

Required: **NO**

Default: *EMPTY*

#### **RUN_AT_STARTUP**

If set to `1`, will perform the backup as soon as the container startup delay finishes. Otherwise, the backup will be performed only after the main schedule interval.

Required: **NO**

Default: `1`

#### **STARTUP_BKP_DELAY_SECS**

Delay interval (in seconds) after the container initialization to wait before entering the main backup routine.

Required: **NO**

Default: `5`

### Postgres Configuration

#### **POSTGRES_DATABASE**

Postgres database name. If empty, all databases will be exported in the dump file.

Required: **NO**

Default: *EMPTY*

#### **POSTGRES_HOST**

Postgres connection host

Required: **YES**

Default: `<host>`¹

#### **POSTGRES_PORT**

Postgres connection port

Required: **NO**

Default: `5432`

#### **POSTGRES_USER**

Postgres connection user

Required: **YES**

Default: `<user>`¹

#### **POSTGRES_PASSWORD**

Postgres connection password

Required: **YES**

Default: `<password>`¹

#### **POSTGRES_EXTRA_OPTS**

Custom extra arguments passed to the Postgres CLI

Required: **NO**

Default: *EMPTY*

### AWS S3 Configuration

#### **S3_REGION**

AWS S3 Region used to store the backup files

Required: **YES**

Default: `<region>`¹

#### **S3_BUCKET**

AWS S3 Bucket used to upload the files

Required: **YES**

Default: `<bucket>`¹

#### **S3_ACCESS_KEY_ID**

AWS S3 Access Key ID used to connect and perform the upload

Required: **YES**

Default: `<key_id>`¹

#### **S3_SECRET_ACCESS_KEY**

AWS S3 Secret Access Key used to connect and perform the upload

Required: **YES**

Default: `<access_key>`¹

#### **S3_PREFIX**

AWS S3 path prefix (subfolder) is used to perform the upload. May be left empty.

Required: **NO**

Default: *EMPTY*

#### **S3_ENDPOINT**

AWS S3 main endpoint URL. Will use the default one when empty.

Required: **NO**

Default: *EMPTY*

## Testing

To execute the ATs, make sure that both the `s3-postgres-backup` container and a `postgres` instance are up and running.

This can be achieved by running the `docker-compose.yaml` file:

```bash
docker compose up --build --remove-orphans
```

Then, after both containers are up and running, run the test script inside the `s3-postgres-backup` container:

```bash
docker exec -i s3-postgres-backup sh -c "cd scripts && ./test.sh"
```

The script will execute with success if all the tests have passed or will abort with an error otherwise. The output is verbose, give a check.

The repository pipelines also include testing for code leaks at [.github/workflows/test_code_leaks.yaml](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/.github/workflows/test_code_leaks.yaml), testing for package vulnerabilities at [.github/workflows/test_grype_scan.yaml](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/.github/workflows/test_grype_scan.yaml), testing for code quality at [.github/workflows/test_code_quality.yaml](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/.github/workflows/test_code_quality.yaml), and E2E ATs (which will call the `./test.sh` script) at [.github/workflows/test_e2e.yaml](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/.github/workflows/test_code_quality.yaml).

## Contributing

If you faced an issue or would like to have a new feature, open an issue in this repository. Please describe your request as detailed as possible (remember to attach binary/big files externally), and wait for feedback. If you're familiar with software development, feel free to open a Pull Request with the suggested solution.

Any help is appreciated! Feel free to review, open an issue, fork, and/or open a PR. Contributions are welcomed!

### Contributors

[ferdn4ndo](https://github.com/ferdn4ndo)

## License

This application is distributed under the [MIT](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/LICENSE) license.
