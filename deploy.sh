#!/usr/bin/env bash

if [ ! -f "private_keys.txt" ]; then
	echo -e "The private_keys.txt file does not exist.\nPlease, create it first."
	exit
fi

install_foundry() {
	curl -L https://foundry.paradigm.xyz | bash
	source ~/.bashrc
	foundryup
}

function create_contract() {
	private_key=$1
	forge init wallet-$2 && cd wallet-$2
	touch .env
	echo ARC_TESTNET_RPC_URL="https://rpc.testnet.arc.network" >> .env
	rm -f src/Counter.sol
	cp ../share/HelloArchitect.sol src/
	rm -rf script
	rm -f test/Counter.t.sol
	cp ../share/HelloArchitect.t.sol test/
	forge test
	forge build
	echo PRIVATE_KEY="$private_key" >> .env
	source .env
	forge create src/HelloArchitect.sol:HelloArchitect \
			--rpc-url $ARC_TESTNET_RPC_URL \
			--private-key $PRIVATE_KEY \
			--broadcast | tee log_contract.txt
	deployed_to=$(cat log_contract.txt | awk '/Deployed to:/ {print $3}')
	echo HELLOARCHITECT_ADDRESS="$deployed_to" >> .env
	source .env
	cast call $HELLOARCHITECT_ADDRESS "getGreeting()(string)" \
			--rpc-url $ARC_TESTNET_RPC_URL
	cd ..
}

# Install Foundry
install_foundry

# Create & interact with the contract
iter=1
while IFS= read -r line; do
    create_contract $line $iter
    iter=$((iter + 1))
done < private_keys.txt