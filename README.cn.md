
## OutswapV1

OutswapV1 基于 UniswapV2 构建，并对 UniswapV2 做了 Blast (Layer 2) 本地化改进以及对做市手续费管理的改进。

OutswapV1 将 Outstake 中的 RETH 与 RUSD 作为交换的基础代币，在 OutswapV1 上，所有与 ETH 和 USDB 相关的活动都会使用 RETH 与 RUSD 作为中间代币，因此 Outstake 将捕获到 OutswapV1 所产生的原生收益。

与 UniswapV2 不同，UniswapV2 只有在移除流动性的时候才会领取做市手续费，做市手续费就包含在移除的流动性中。而OutswapV1 将流动性与做市手续费分离，用户可以在不移除流动性的情况下单独领取手续费，这样做能让用户更好地管理自己的仓位，同时适配我们的 FFLaunch 产品，这点在 FFLaunc h的文档中有详细的说明。

在不久未来我们还会对 OutswapV1 进行升级，提高 Outswap 的资本利用率，降低滑点，给用户带来更丝滑的体验。
