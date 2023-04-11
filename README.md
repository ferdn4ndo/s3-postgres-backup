# S3 Postgres Backup

[![GitLeaks badge](https://img.shields.io/badge/protected%20by-GitLeaks-blue)](https://github.com/gitleaks/gitleaks-action/)
[![GitLeaks test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_code_leaks.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![Grype badge](https://img.shields.io/badge/protected%20by-Grype-blue)](https://github.com/anchore/grype)
[![Grype test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_grype_scan.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![ShellCheck badge](https://img.shields.io/badge/code%20quality%20by-ShellCheck-blue)](https://github.com/koalaman/shellcheck)
[![ShellCheck test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_code_quality.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![E2E test status](https://github.com/ferdn4ndo/s3-postgres-backup/actions/workflows/test_e2e.yaml/badge.svg?branch=main)](https://github.com/ferdn4ndo/s3-postgres-backup/actions)
[![Release](https://img.shields.io/github/v/release/ferdn4ndo/s3-postgres-backup)](https://github.com/ferdn4ndo/s3-postgres-backup/releases)
[![MIT license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)

An Alpine-based docker image to automatically perform periodic dumps of a Postgres server to an S3 bucket. Supports encryption, compression, and restoration. Protected against code leakage by [GitLeaks](https://github.com/gitleaks/gitleaks-action/) and package vulnerabilities by [Anchore Grype](https://github.com/anchore/grype). CI pipeline with code quality check by [Shellcheck](https://github.com/koalaman/shellcheck) and internal E2E Automated Tests (ATs).

## How to run?

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

If you faced an issue or would like to have a new feature, open an issue in this repository. Please describe your request as detailed as possible (remember to attach binary/big files externally), and wait for feedback. If you're familiar with software development, feel free to open a Pull Request with the suggested solution. Contributions are welcomed!

## License

This application is distributed under the [MIT](https://github.com/ferdn4ndo/s3-postgres-backup/blob/main/LICENSE) license.

## Contributors

[ferdn4ndo](https://github.com/ferdn4ndo)

Any help is appreciated! Feel free to review, open an issue, fork, and/or open a PR.
