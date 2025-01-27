# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
install:; forge install
update:; forge update

# Build & test
build  :; forge build
test   :; forge test --no-match-contract CompoundERC4626\|StETHERC4626.*Test
trace  :; forge test -vvv --no-match-contract CompoundERC4626\|StETHERC4626.*Test
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt && forge fmt test/
test-mainnet-fork :; forge test --fork-url $(RPC_URL_MAINNET) --match-contract CompoundERC4626\|StETHERC4626.*Test -vvv
integration-test :; forge test --fork-url $(RPC_URL_MAINNET) --match-path *Integration* -vvv