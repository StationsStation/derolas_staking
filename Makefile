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
	forge coverage -vvvv \
		--fork-url https://mainnet.base.org

lcov:
	forge coverage -vvvv \
		--fork-url https://mainnet.base.org \
		--report lcov \
		-r coverage/lcov.info
	genhtml coverage/lcov.info -o coverage/html

ci:
	act

all: fmt lint build tests