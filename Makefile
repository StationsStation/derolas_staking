install:
	yarn
	forge install

fmt:
	forge fmt
	forge fmt --check
	yarn run solhint \
		--config .solhint.json \
		--fix \
		--noPrompt \
		--noPoster \
		--quiet \
		src/**/*.sol \
		test/**/*.sol

lint:
	yarn run solhint \
		--config .solhint.json \
		--quiet \
		--noPrompt \
		src/**/*.sol \
		test/**/*.sol

build:
	forge build

tests:
	forge test -vvvv \
		--fork-url https://mainnet.base.org

ci:
	act

all: fmt lint build tests