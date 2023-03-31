# load environment variables from .env
source .env

# set env variables
export ADDRESSES_FILE=./deployments/optimism.json
export RPC_URL=$RPC_URL_OPTIMISM

# load common utilities
. $(dirname $0)/../common.sh

# deploy contracts
exactly_factory_address=$(deploy ExactlyERC4626Factory $EXACTLY_AUDITOR_OPTIMISM $EXACTLY_FACTORY_OWNER_OPTIMISM)
echo "ExactlyERC4626Factory=$exactly_factory_address"