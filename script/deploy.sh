source ../.env
#forge clean && forge build
forge script OutswapV1Script.s.sol:OutswapV1Script --rpc-url blast_sepolia \
    --priority-gas-price 300 --with-gas-price 1200000 \
    --optimize --optimizer-runs 5000 \
    --broadcast --verify --ffi -vvvv
