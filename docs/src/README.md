# <h1 align="center"> Derolas Staking</h1>

**Derolas Staking and Donation Auction**

![Github Actions](https://github.com/StationsStation/derolas_staking/workflows/CI/badge.svg)

## Getting Started

This repository contains a simple staking contract that allows users to stake tokens and receive rewards based on their stake. It also includes a donation auction feature where agents donate tokens to a pool and the donation itself is used to determine whether the agent is eligible for staking rewards.

## Prerequisites

- [Foundry](https://getfoundry.sh) - A blazing fast, portable and modular toolkit for Ethereum application development.

### Optional Dependencies
- [Node.js](https://nodejs.org) - JavaScript runtime for running scripts and linters.
- [Docker](https://www.docker.com) - Platform for developing, shipping, and running applications in containers.
- [nektos/act](https://github.com/nektos/act) - Run GitHub Actions locally using Docker.
- [lcov](https://github.com/linux-test-project/lcov) - A graphical front-end for GCC's coverage testing tool gcov.


```bash
git clone https://github.com/StationsStation/derolas_staking.git --recursive
cd derolas_staking
make install
```
## Documentation

```bash
make doc
```

## Development

## Testing
This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

Run the tests using the following command:

```bash
make test
```
This will run all the tests in the `test` directory and output the results to the console

## Linting
This project uses [solhint](https://protofire.github.io/solhint/) for linting Solidity code. To run the linter, use the following command:

```bash
make lint
```
This will check all Solidity files in the `src` directory for linting errors and output the results to the console.

## Formatting
Forge standard formatting is used for Solidity files. To format the code, use the following command:

```bash
make fmt
```

## Running Ci Locally
To run the CI checks locally, you can use the following command:
```bash
make ci
```
This will use nektos/act to run the CI checks in a Docker container. Make sure you have Docker installed and running on your machine.
- [Docker](https://www.docker.com) - Platform for developing, shipping, and running applications in containers.
- [nektos/act](https://github.com/nektos/act) - Run GitHub Actions locally using Docker.

## Coverage
To generate code coverage reports, you can use the following command:

```bash
make lcov
```

The coverage reports will be generated in the `coverage` directory. You can view the reports by opening the `index.html` file in a web browser.
