# load environment variables from .env
source .env

# set env variables
export ADDRESSES_FILE=./deployments/optimism.json
export RPC_URL=$RPC_URL_OPTIMISM

# load common utilities
. $(dirname $0)/../common.sh

# deploy contracts
compound_factory_address=$(deploy CompoundERC4626Factory $COMPOUND_COMPTROLLER_OPTIMISM $COMPOUND_CETHER_OPTIMISM $COMPOUND_REWARDS_RECIPIENT_OPTIMISM)
echo "CompoundERC4626Factory=$compound_factory_address"