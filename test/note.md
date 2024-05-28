## bug example
- [X] 1. swapRouter.swapExactTokensForETH用token交换eth, 需要将ORETH换成ETH，调用`ORETH.withdrw()`，ORETH 通过`OutETHVault.withdraw()`调用金库合约转账给router，此时msg.sender转变为 ETHValut地址，而router.receive()要求 msg.sender == ORETH，assertion failed。
   - 测试函数位置：test/SimpleSwap.t.sol:test_SwapUSDBtoETHtoORETH 和 swapToken
   - 相关文件：test/utils/ORETH.sol：59 以及test/BaseDeploy.t.sol:OutVault 26
    ```
        swap/src/router/OutswapV1Router.sol::function swapExactTokensForETH(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
            ...
    @>      IORETH(ORETH).withdraw(amounts[amounts.length - 1]);                            // 1
            TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        }

        src/token/ETH/ORETH.sol：：function withdraw(uint256 amount) external override {
            ...
            IOutETHVault(outETHVault).withdraw(user, amount);                           // 2
            ...
        }

        stake/src/vault/OutETHVault.sol::function withdraw(address user, uint256 amount) external override onlyORETHContract {
            Address.sendValue(payable(user), amount);                                   // 3
        }

        swap/src/router/OutswapV1Router.sol::receive() external payable {
            assert(msg.sender == ORETH); // only accept ETH via fallback from the ORETH contract  //  4
        }
    ```
    测试输出结果如下：
    ```

            [70856] OutswapV1Router::swapExactTokensForETH(1000, 0, [0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9, 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0], 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1)
        │   ├─ [437] OutswapV1Pair::getReserves() [staticcall]
        │   │   └─ ← 9902, 101000 [1.01e5], 1
        │   ├─ [3544] TestERC20::transferFrom(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4], 1000)
        │   │   ├─ emit Transfer(from: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, to: OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4], value: 1000)
        │   │   └─ ← true
        │   ├─ [37625] OutswapV1Pair::swap(96, 0, OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], 0x)
        │   │   ├─ [24962] ORETH::transfer(OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], 96)
        │   │   │   ├─ emit Transfer(from: OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4], to: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], value: 96)
        │   │   │   └─ ← true
        │   │   ├─ [626] ORETH::balanceOf(OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4]) [staticcall]
        │   │   │   └─ ← 9806
        │   │   ├─ [563] TestERC20::balanceOf(OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4]) [staticcall]
        │   │   │   └─ ← 102000 [1.02e5]
        │   │   ├─ emit Sync(reserve0: 9806, reserve1: 102000 [1.02e5])
        │   │   ├─ emit Swap(sender: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], amount0In: 0, amount1In: 1000, amount0Out: 96, amount1Out: 0, to: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F])
        │   │   └─ ← ()
        │   ├─ [19703] ORETH::withdraw(96)
        │   │   ├─ emit Transfer(from: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], to: 0x0000000000000000000000000000000000000000, value: 96)
        │   │   ├─ [7284] OutVault::withdraw(OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], 96)
    @>  │   │   │   ├─ [173] OutswapV1Router::receive{value: 96}()
        │   │   │   │   └─ ← panic: assertion failed (0x01)
        │   │   │   └─ ← panic: assertion failed (0x01)
        │   │   └─ ← panic: assertion failed (0x01)
        │   └─ ← panic: assertion failed (0x01)
        └─ ← panic: assertion failed (0x01)
      ```
[] 2. Precision Loss
  - Summary
    - 问题描述: OutswapV1Pair::swap每次交易对流动性收益进行更新，`accumFeePerLP + ((rootK - rootKLast) / totalSupply);`，当每笔交易进行更新时，K值增发量远远小于totoalSupply，进而造成精度缺失，进一步造成流动性收益比实际获得的少很多, 甚至直接为0.
  - Detail
    - 问题类型：Precision Loss
    - 严重程度：Low
    - 影响分析：Fund locked and profit lost
  - Location
    - Contract name: OutswapV1Pair
    - Code line: 269
    ```
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        ...
        {   
            uint256 k = uint256(reserve0) * uint256(reserve1);
            accumFeePerLP = _accumulate(Math.sqrt(k), Math.sqrt(kLast));
            kLast = k;
        }
        ...
    }
    ```
 - PoC
   - 前置条件：
     - 创建池子，并且提供流动性 `(,,, tokenPair) = addLiquidityTokenAndUSDB(tokens[0], 4 ether, 8 ether);`
     - tokenPair_totoalSupply = 5.656854249492380195 * 10e18
   - 步骤：
     - 进行10笔交易，每笔swap数量为 `totoalSupply/10`，交易过后，读取流动性累计收益均为0
        ```
        function test_MintFee_NonProfit_Times() public {
          uint256 amountOut = totalSupply / 10;
          uint256 totoalAmount = totalSupply;

          vm.startPrank(deployer);
          
          for (int i = 0; i < 10; i++){
              uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, amountOut, tokenToUsdPath);
              IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
              IOutswapV1Pair(tokenPair).swap(0, amountOut, address(this), "");

              accumFeePerLP = IAccumFeePerLP(tokenPair).accumFeePerLP();
              assertEq(accumFeePerLP, 0);
          }
          vm.stopPrank();
        }
        ```
     - 进行1笔交易，数量为 `totoalSupply + 1 ether`，交易过后，读取流动性累计收益为0
        ```
        function test_MintFee_NonProfit() public {
            uint112 reserve0;
            uint112 reserve1;
            uint256 totoalAmount = totalSupply + 1 ether;

            vm.startPrank(deployer);
            uint256[] memory amountsCal = OutswapV1Library.getAmountsIn(OutswapV1Factory, totoalAmount, tokenToUsdPath);
            IERC20(tokenToUsdPath[0]).transfer(tokenPair, amountsCal[0]);
            IOutswapV1Pair(tokenPair).swap(0, totoalAmount, address(this), "");
            vm.stopPrank();

            (reserve0, reserve1, ) = IOutswapV1Pair(tokenPair).getReserves();
            uint256 k = uint256(reserve0) * uint256(reserve1);

            accumFeePerLP = _accumulate(Math.sqrt(k), Math.sqrt(kLast));
            assertEq(accumFeePerLP, 0);
        }
        ```
        对rootK， rootKLast以及计算累计流动性收益公式进行debug，log如下，很明显，当增发的流动性小于totoalSupply时，accumFeePerLP始终为0：
        ```
        (rootK - rootKLast): 0.007077478455129232 * 10e18
        OutswapV1Pair: 5.656854249492380195 * 10e18
        ```
        现在再看一下，手续费怎么收的，了解增发流动性的数学原理，每次swap 收0.3% 手续费，基本上能够确定每次swap的增发流动性绝对小于totoalSupply
        ```
         {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            require(
                balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * 1000 ** 2,
                "OutswapV1: K"
            );
        }
        ```
      - 完整测试代码在：test/MintFeeTest.t.sol
    - 因为精度偏移造成损失会进行累计
    - Recommendations 
      1. 精度偏移
        ```
        function _accumulate_update(uint256 rootK, uint256 rootKLast) internal  returns (uint256) {
           // emit log_named_decimal_uint("(rootK - rootKLast):", (rootK - rootKLast), 18);
           // emit log_named_decimal_uint("OutswapV1Pair", totalSupply, 18);
           return accumFeePerLP + ((rootK - rootKLast) * 10e18  / totalSupply);
         }
        ```
      2. 设定 accumFeePerLP 更新时间
