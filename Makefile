install:
	yarn
	forge install

fmt:
	forge fmt
	forge fmt --check
	yarn run solhint \
		--config .solhint.json src/**/*.sol \
		--fix \
		--noPrompt \
		--noPoster \
		--quiet

lint:
	yarn run solhint \
		--config .solhint.json src/**/*.sol \
		--quiet \
		--noPrompt

build:
	forge build

tests:
	forge test

ci:
	act

all: fmt lint build tests