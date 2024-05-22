
## OutswapV1

OutswapV1 基于 UniswapV2 构建，并对 UniswapV2 做了 Blast (Layer 2) 本地化改进以及对做市手续费管理的改进。

### 为什么基于 UniswapV2 构建而不是Uniswap V3？
我们分析了Uniswap V3的交易对数据，发现Uniswap V3的大部分交易量都集中在主流币交易对和稳定币交易对，类似 USDT/USDC, ETH/USDT, ETH/USDC, WBTC/USDT, ETH/ETH_LST，并且Uniswap V3需要专业的仓位管理，对非专业交易员来说，无常损失很高。重要的一点是，对于新资产，Uniswap V3并不友好，因为它不能提供稳定的流动性，而且会造成流动性碎片化，毕竟当你在对 meme Coin 提供流动性时，你也很难确定价格区间的上界与下界。所以在我们的 OutswapV1 获得足够的流动性后我们才会推出集中流动性 AMM 版本 - OutswapV2.

### OutswapV1的特点？
OutswapV1 将 Outstake 中的 RETH 与 RUSD 作为交换的基础代币，在 OutswapV1 上，所有与 ETH 和 USDB 相关的活动都会使用 RETH 与 RUSD 作为中间代币，因此 Outstake 将捕获到 OutswapV1 所产生的原生收益。

与 UniswapV2 不同，UniswapV2 只有在移除流动性的时候才会领取做市手续费，做市手续费就包含在移除的流动性中。而OutswapV1 将流动性与做市手续费分离，用户可以在不移除流动性的情况下单独领取手续费，这样做能让用户更好地管理自己的仓位，同时适配我们的 FFLaunch 产品，这点在 FFLaunch 的文档中有详细的说明。

在不久的未来，我们还会对 OutswapV1 进行升级，提高 Outswap 的资本利用率，降低滑点，给用户带来更丝滑的体验。
