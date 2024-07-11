source ../.env
forge clean && forge build
forge script OutswapV1Script.s.sol:OutswapV1Script --rpc-url blast_sepolia \
    --priority-gas-price 300 --with-gas-price 1200000 \
    --broadcast --verify --ffi -vvvv

# forge verify-contract \
#     --verifier-url https://api-sepolia.blastscan.io/api \
#     --chain-id 168587773 \
#     --optimizer-runs 5000 \
#     --watch \
#     --constructor-args $(cast abi-encode "constructor(address,address,address,address,address,address)" 0x3de10cF7B1b3442743C758528695D9e9246aaAfE 0x99766FEb8EA7F357bDBa860998D1Fb44d7fb89eA 0x6D78F8523Be0d36DDB874B4db5570c7E034F250A 0x4200000000000000000000000000000000000022 0x72A040320E8920694803E886D733d9BBDCd94AF8 0xcae21365145C467F8957607aE364fb29Ee073209) \
#     --etherscan-api-key FXRA5Z5Q8SE1HHICND2KK92KB1CH97N4TK \
#     --compiler-version v0.8.24+commit.e11b9ed9 \
#     0x61FF5251058366682817E1061d5BfBca1539aD6E \
#     src/router/OutswapV1Router01.sol:OutswapV1Router01 
