#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
reset=$(tput sgr0)

# Get globals file
globals="$(dirname "$0")/globals_$1.json"
if [ ! -f $globals ]; then
  echo "${red}!!! $globals is not found${reset}"
  exit 0
fi

# Read variables using jq
contractVerification=$(jq -r '.contractVerification' $globals)
useLedger=$(jq -r '.useLedger' $globals)
derivationPath=$(jq -r '.derivationPath' $globals)
chainId=$(jq -r '.chainId' $globals)
networkURL=$(jq -r '.networkURL' $globals)

minDonation=$(jq -r '.minDonation' $globals)
balancerRouter=$(jq -r '.balancerRouter' $globals)
balancerVaultAdmin=$(jq -r '.balancerVaultAdmin' $globals)
poolId=$(jq -r '.poolId' $globals)
assetsInPool=$(jq -r '.assetsInPool' $globals)
olasAddress=$(jq -r '.olasAddress' $globals)
incentiveTokenIndex=$(jq -r '.incentiveTokenIndex' $globals)
wethIndex=$(jq -r '.wethIndex' $globals)
availableRewards=$(jq -r '.availableRewards' $globals)
roundLength=$(jq -r '.roundLength' $globals)

contractPath="src/DerolasAuction.sol:DerolasAuction"
constructorArgs="$minDonation $balancerRouter $balancerVaultAdmin $poolId $assetsInPool $olasAddress $incentiveTokenIndex $wethIndex $availableRewards $roundLength"
contractArgs="$contractPath --constructor-args $constructorArgs"

# Get deployer based on the ledger flag
if [ "$useLedger" == "true" ]; then
  walletArgs="-l --mnemonic-derivation-path $derivationPath"
  deployer=$(cast wallet address $walletArgs)
else
  echo "Using PRIVATE_KEY: ${PRIVATE_KEY:0:6}..."
  walletArgs="--private-key $PRIVATE_KEY"
  deployer=$(cast wallet address $walletArgs)
fi

# Deployment message
echo "${green}Deploying from: $deployer${reset}"
echo "RPC: $networkURL"
echo "${green}Deployment of: $contractArgs${reset}"

# Deploy the contract and capture the address
execCmd="forge create --broadcast --rpc-url $networkURL$API_KEY $walletArgs $contractArgs"
deploymentOutput=$($execCmd)
derolasAuctionAddress=$(echo "$deploymentOutput" | grep 'Deployed to:' | awk '{print $3}')

# Get output length
outputLength=${#derolasAuctionAddress}

# Check for the deployed address
if [ $outputLength != 42 ]; then
  echo "${red}!!! The contract was not deployed...${reset}"
  exit 0
fi

# Write new deployed contract back into JSON
echo "$(jq '. += {"derolasAuctionAddress":"'$derolasAuctionAddress'"}' $globals)" > $globals

# Verify contract
if [ "$contractVerification" == "true" ]; then
  contractParams="$derolasAuctionAddress $contractPath --constructor-args $(cast abi-encode "constructor(uint256,address,address,address,uint256,address,uint256,uint256,uint256,uint256)" $constructorArgs)"
  echo "Verification contract params: $contractParams"

  echo "${green}Verifying contract on Etherscan...${reset}"
  forge verify-contract --chain-id "$chainId" --etherscan-api-key "$ETHERSCAN_API_KEY" $contractParams

  blockscoutURL=$(jq -r '.blockscoutURL' $globals)
  if [ "$blockscoutURL" != "null" ]; then
    echo "${green}Verifying contract on Blockscout...${reset}"
    forge verify-contract --verifier blockscout --verifier-url "$blockscoutURL/api" $contractParams
  fi
fi

echo "${green}Contract deployed at: $derolasAuctionAddress${reset}"