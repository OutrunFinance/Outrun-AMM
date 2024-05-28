
## OutswapV1

OutswapV1 基于 UniswapV2 构建，并针对 UniswapV2 进行了多项基于 Blast (Layer 2) 的本地化改进。具体来说，OutswapV1 引入了 orETH 和 orUSD 作为中间代币，并对做市手续费管理进行了重要改进。以下是其主要特点：

+ **使用 orETH 和 orUSD 作为中间代币**：OutswapV1 引入了 orETH 和 orUSD 作为交易对中的中间代币。这种设计可以使得Outstake捕获到OutswapV1产生的原生收益，提高协议产生的收益，同时利用 Layer 2 的优势来降低交易成本和提高交易速度。

+ **流动性与做市手续费分离**：OutswapV1 改进了做市手续费的管理方式，将流动性与做市手续费的获取分离，使得用户可以在不移除流动性的情况下单独领取手续费。这种改进为流动性提供者带来了更大的灵活性和便利性。

### 为什么基于 UniswapV2 构建而不是 Uniswap V3？
我们分析了 UniswapV3 的交易对数据，发现 UniswapV3 的大部分交易量都集中在主流币交易对和稳定币交易对，类似 **USDT/USDC, ETH/USDT, ETH/USDC, WBTC/USDT, ETH/ETH_LST**.

并且 UniswapV3 需要专业的仓位管理，对非专业交易员来说，无常损失很高。重要的一点是，对于新资产，UniswapV3 并不友好，因为它不能提供稳定的流动性，而且会造成流动性碎片化，毕竟当你在对 meme coin 提供流动性时，你也很难确定价格区间的上界与下界。

所以在我们的 OutswapV1 获得足够的流动性后我们才会推出集中流动性 AMM 版本 - **OutswapV2**.

### OutswapV1 的特点？
在 OutswapV1 上，所有与 ETH 和 USDB 相关的活动都会使用 orETH 与 orUSD 作为中间代币，因此 Outstake 将捕获到 OutswapV1 所产生的原生收益。

与 UniswapV2 不同，UniswapV2 只有在移除流动性的时候才会领取做市手续费，做市手续费就包含在移除的流动性中。而 OutswapV1 将流动性与做市手续费分离，用户可以在不移除流动性的情况下单独领取手续费，这样做能让用户更好地管理自己的仓位，同时适配我们的 FFLaunch 产品。
