//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {Test, console2} from "forge-std/Test.sol";
// import {OutswapV1Router} from "src/router/OutswapV1Router.sol";
// import { OutswapV1Pair } from "src/core/OutswapV1Pair.sol";

import {TestERC20} from "./utils/TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRETH} from "./interfaces/IRETH.sol";
import {IOutswapV1Factory} from "src/core/interfaces/IOutswapV1Factory.sol";
import {IOutswapV1Router} from "src/router/interfaces/IOutswapV1Router.sol";

string constant RETHAtricle = "test/utils/RETH.json";
string constant RUSDAtricle = "test/utils/RUSD.json";
string constant factoryAtricle = "out/OutswapV1Factory.sol/OutswapV1Factory.json";
string constant routerAtricle = "out/OutswapV1Router.sol/OutswapV1Router.json";

contract OutVault {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(address sender, uint256 amount) external {
        payable(sender).transfer(amount);
    }

    receive() external payable {}
    fallback() external payable {}
}

contract BaseDeploy is Test {
    address public deployer = vm.envAddress("LOCAL_DEPLOYER");

    IOutswapV1Factory internal poolFactory;
    IOutswapV1Router internal swapRouter;

    address internal RETH9;
    address internal RUSD9;
    address internal USDB;

    address internal ethVault;
    address internal usdVault;

    uint256 immutable tokenNumber = 3;

    address[] tokens;

    function setUp() public virtual {
        uint256 forkId = vm.createFork("blast_sepolia");
        vm.selectFork(forkId);

        vm.startPrank(deployer);

        deployNewEnv();

        getToken();

        vm.stopPrank();
    }

    function deployNewEnv() internal {
        ethVault = address(new OutVault());
        usdVault = address(new OutVault());

        RETH9 = deployCode(RETHAtricle, abi.encode(deployer));
        RUSD9 = deployCode(RUSDAtricle, abi.encode(deployer));
        USDB = address(new TestERC20(type(uint256).max / 2));

        IRETH(payable(RETH9)).setOutETHVault(ethVault);

        vm.deal(deployer, 10e10 ether);
        IRETH(payable(RETH9)).deposit{value: 100 ether}();

        address factory = deployCode(factoryAtricle, abi.encode(deployer));
        poolFactory = IOutswapV1Factory(factory);

        address router = deployCode(routerAtricle, abi.encode(address(poolFactory), RETH9, RUSD9, USDB));
        swapRouter = IOutswapV1Router(router);
    }

    function getToken() internal {
        for (uint256 i = 0; i < tokenNumber; i++) {
            address token = address(new TestERC20(type(uint256).max / 2));
            tokens.push(token);
            safeApprove(token, address(swapRouter), type(uint256).max / 2);
        }
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amount0, uint256 amount1)
        internal
        virtual
        returns (uint256, uint256, uint256)
    {
        return addLiquidity(address(swapRouter), tokenA, tokenB, amount0, amount1);
    }

    function addLiquidity(address router, address tokenA, address tokenB, uint256 amount0, uint256 amount1)
        internal
        virtual
        returns (uint256, uint256, uint256)
    {
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        return IOutswapV1Router(router).addLiquidity(
            tokenA, tokenB, amount0, amount1, 0, 0, deployer, block.timestamp + 1 days
        );
    }



    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }
}
