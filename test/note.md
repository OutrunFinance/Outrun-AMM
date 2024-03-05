## bug example
1. swapRouter.swapExactTokensForETH用token交换eth, 需要将RETH换成ETH，调用`RETH.withdrw()`，RETH 通过`OutETHVault.withdraw()`调用金库合约转账给router，此时msg.sender转变为 ETHValut地址，而router.receive()要求 msg.sender == RETH，assertion failed。
   - 测试函数位置：test/SimpleSwap.t.sol:test_SwapUSDBtoETHtoRETH9 和 swapToken
   - 相关文件：test/utils/RETH.sol：59 以及test/BaseDeploy.t.sol:OutVault 26
```
    swap/src/router/OutswapV1Router.sol::function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        ...
@>      IRETH(RETH).withdraw(amounts[amounts.length - 1]);                            // 1
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    src/token/ETH/RETH.sol：：function withdraw(uint256 amount) external override {
        ...
        IOutETHVault(outETHVault).withdraw(user, amount);                           // 2
        ...
    }

    stake/src/vault/OutETHVault.sol::function withdraw(address user, uint256 amount) external override onlyRETHContract {
        Address.sendValue(payable(user), amount);                                   // 3
    }

    swap/src/router/OutswapV1Router.sol::receive() external payable {
        assert(msg.sender == RETH); // only accept ETH via fallback from the RETH contract  //  4
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
    │   │   ├─ [24962] RETH::transfer(OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], 96)
    │   │   │   ├─ emit Transfer(from: OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4], to: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], value: 96)
    │   │   │   └─ ← true
    │   │   ├─ [626] RETH::balanceOf(OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4]) [staticcall]
    │   │   │   └─ ← 9806
    │   │   ├─ [563] TestERC20::balanceOf(OutswapV1Pair: [0xe478bd237Ccacfc9960E6E15Ff8880E3eA4adAe4]) [staticcall]
    │   │   │   └─ ← 102000 [1.02e5]
    │   │   ├─ emit Sync(reserve0: 9806, reserve1: 102000 [1.02e5])
    │   │   ├─ emit Swap(sender: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], amount0In: 0, amount1In: 1000, amount0Out: 96, amount1Out: 0, to: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F])
    │   │   └─ ← ()
    │   ├─ [19703] RETH::withdraw(96)
    │   │   ├─ emit Transfer(from: OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], to: 0x0000000000000000000000000000000000000000, value: 96)
    │   │   ├─ [7284] OutVault::withdraw(OutswapV1Router: [0x0165878A594ca255338adfa4d48449f69242Eb8F], 96)
@>  │   │   │   ├─ [173] OutswapV1Router::receive{value: 96}()
    │   │   │   │   └─ ← panic: assertion failed (0x01)
    │   │   │   └─ ← panic: assertion failed (0x01)
    │   │   └─ ← panic: assertion failed (0x01)
    │   └─ ← panic: assertion failed (0x01)
    └─ ← panic: assertion failed (0x01)
  ```
