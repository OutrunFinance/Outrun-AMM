source ../.env
forge clean && forge build
forge script OutswapV1Script.s.sol:OutswapV1Script --rpc-url sepolia --broadcast --verify --ffi