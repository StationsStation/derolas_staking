# <h1 align="center"> Derolas Staking</h1>

![Github Actions](https://github.com/StationsStation/derolas_staking/workflows/CI/badge.svg)

**Derolas Staking and Donation Auction**

## Introduction

This repository contains a simple staking contract that allows users to stake tokens and receive rewards based on their stake. It also includes a donation auction feature where agents donate eth to a pool and the donation itself is used to determine whether the agent is eligible for staking rewards.


## Arctitecture and Design

The project is made of two major contracts, The auction and the staking manager.

The auction is designed to incentivise donations to a balancer pool.

This donation function is beneficial for a number of reasons;

- By calling donate, no additional LP tokens are issued. This has the net effect of increasing the value within the LP, thereby increasing the share price of each of the LP tokens.

### Proportional Auction Process

Each round of the auction process is determined by a number of key variables;

- Length:               How long the auction will last in blocks.
- MinDonation:          A lower bound on the minimum donation necessary to participate in the auction.
- AvailableRewards:     Number of `IncentiveToken` to be distributed in the auction.

Each auction will distribute the `AvailableRewards` to the participants of the auction based on the amount they have donated.

Rewards aer distributed to the following formula;
```
        amount = (donation * availableRewards) / totalRoundDonations;
```

For example if there is a total of 5 donors who all donated `MinDonation` then the available rewards will be equally distributed amongst all participants.

Another example would be where a single donor donates a disproportionally large amount compared to the minimum donation. Let us say that we have 3 donors who donate in the following proportions.

- Donor A) 10
- Donor B) 5
- Donor C) 5

The rewards would be distributed as so;

- Donor A) receives 50%
- Donor B) receives 25%
- Donor C) receives 25%

Hence, Proportional Auction.

Note, this can lead to a case whereby all donors overpay for the rewards based on the current price. 

### Caveats

- Limited Claim windows: Donations can ONLY be claimed 1 round after they have been earnt. Thus any unclaimed rewards from curRound -2 should be immediately donated to the balancer pool.

- Multiple Balancer Flows: 
    - Donations: All eth donated to participate within the auctions are donated to the balancer pool.
    - Unclaimed Incentive Tokens: Donors who DO NOT CLAIM in the round after they donate have their rewards swept into the pool.

- One Donation per Auction: It is impossible for any agent to donate more than once per auction round. This is to ensure that the auction is fair and that no agent can dominate the auction by donating multiple times.

### Activity Checking & Olas Staking Ecosystem

In the Olas ecosystem exists the concept of the Daily Active Agents.

In order to achieve remain compatible with this, the measure of daily active agent within the Derolas Ecosystem is whether the associated multi-sig has participated within *any* auction round within the past 24h.

This information is stored within the mapping `epochDonationActivities`.

As per the standard Olas Daily Active Agent interface, this requires a isRatioPass for a single staker.

Note, the design of the contracts allows the seperation of the auctions and the staking which enables auctions (occuring each 90 blocks by default) to run without impacting staking. I.e. in order for a service to be eligible for staknig rewards, it must participate in only 1 Aution each 24 hours.

## Getting Started

One can participate in the auctions on the [Derolas](http://derolas.xyz) frontend.

The following instructions are for developers interested in running and testing locally.

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

You can then navigate to `http://0.0.0.0:4000/` in your web browser to view the documentation.

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


### Releasing
To release a new version of the project, you can use the following command:

```bash
export NEW_VERSION=0.1.0 # Set the new version number
poetry run tbump $NEW_VERSION
```