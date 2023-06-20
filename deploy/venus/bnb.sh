# load environment variables from .env
source .env

# set env variables
export ADDRESSES_FILE=./deployments/bnb.json
export RPC_URL=$RPC_URL_BNB

# load common utilities
. $(dirname $0)/../common.sh

# deploy contracts
venus_factory_address=$(deploy VenusERC4626Factory $VENUS_COMPTROLLER_BNB $VENUS_CETHER_BNB $VENUS_REWARDS_RECIPIENT_BNB)
echo "VenusERC4626Factory=$venus_factory_address"