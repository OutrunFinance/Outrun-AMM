source ../.env
forge clean && forge build
forge script OutswapV1Script.s.sol:OutswapV1Script --rpc-url blast_sepolia --priority-gas-price 300 --with-gas-price 1200000 --optimize --optimizer-runs 100000 --broadcast --verify --ffi -vvvv

# forge script OutswapV1Script.s.sol:OutswapV1Script --chain-id 168587773 --rpc-url blast_sepolia \
#     --etherscan-api-key $BLASTSCAN_API_KEY --verifier-url $BLAST_API_URL \
#     --priority-gas-price 300 --with-gas-price 1200000 \
#     --broadcast --verify --ffi -vvvv
