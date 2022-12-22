# load environment variables from .env
source .env

# set env variables
export ADDRESSES_FILE=./deployments/mainnet.json
export RPC_URL=$RPC_URL_MAINNET

# load common utilities
. $(dirname $0)/../common.sh

# deploy contracts
euler_factory_address=$(deploy StakeableEulerERC4626Factory $EULER_MAINNET $EULER_MARKETS_MAINNET $EULER_REWARDS_DISTRIBUTION_MAINNET $EULER_OWNER_MAINNET)
echo "StakeableEulerERC4626Factory=$euler_factory_address"