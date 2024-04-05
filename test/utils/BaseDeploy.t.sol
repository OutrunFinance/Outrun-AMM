//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma abicoder v2;

import {Test, console2} from "forge-std/Test.sol";
import {OutswapV1Library, OutswapV1Library} from 'src/libraries/OutswapV1Library.sol';

import {TestERC20} from "./TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRUSD} from "../interfaces/IRUSD.sol";
import {IRETH} from "../interfaces/IRETH.sol";
import {IUSDB} from "../interfaces/IUSDB.sol";
import {IOutswapV1Factory} from "src/core/interfaces/IOutswapV1Factory.sol";
import {IOutswapV1Router} from "src/router/interfaces/IOutswapV1Router.sol";
import {IOutswapV1Pair} from "src/core/interfaces/IOutswapV1Pair.sol";

string constant RETHAtricle = "test/RETH.json";
string constant RUSDAtricle = "test/RUSD.json";
string constant factoryAtricle = "out/OutswapV1Factory.sol/OutswapV1Factory.json";
string constant routerAtricle = "out/OutswapV1Router.sol/OutswapV1Router.json";

// INIT_CODE_PAIR_HASH
// 0x15473738582da33766fff6f483b07801985dcd171e0eeb8fac981e06f93b6210
contract BaseDeploy is Test {
    
    address public deployer = vm.envAddress("LOCAL_DEPLOYER");

    address OutswapV1Factory = 0x88fD87C733a661875fC94bbb49CE93e85bbb0dB4;
    address OutswapV1Router = 0xb98E2bBb71A64Eb704f74A56Ad1C014B3530B79C;

    IOutswapV1Factory public poolFactory = IOutswapV1Factory(OutswapV1Factory);
    IOutswapV1Router public swapRouter = IOutswapV1Router(OutswapV1Router);

    address public RETH9 = 0x4E06Dc746f8d3AB15BC7522E2B3A1ED087F14617;
    IRETH public reth = IRETH(RETH9);
    address public RUSD9 = 0x671540e1569b8E82605C3eEA5939d326C4Eda457;
    IRUSD public rusd = IRUSD(RUSD9);
    address public USDB = 0x4200000000000000000000000000000000000022;
    IUSDB public usdb = IUSDB(USDB);


    address public ethVault = 0x6a120b799AEF815fDf2a571B4BD7Fcfe93160135;
    address public usdVault = 0xC92d49c71b6E7B9724E4891e8594907F40aD9AFA;

    uint256 internal tokenNum = 3;

    address[] public tokens;

    function setUp() public virtual {
        uint256 forkId = vm.createFork("blast_sepolia");
        vm.selectFork(forkId);

        vm.label(OutswapV1Factory, "OutswapV1Factory");
        vm.label(OutswapV1Router, "OutswapV1Router");
        vm.label(RETH9, "RETH9");
        vm.label(RUSD9, "RUSD9");
        vm.label(USDB, "USDB");
        vm.label(ethVault, "ethVault");
        vm.label(usdVault, "usdVault");

        vm.deal(deployer, 100 ether);

        vm.prank(IUSDB(USDB).bridge());
        IUSDB(USDB).mint(deployer, 100 ether);

        vm.startPrank(deployer);
        IRETH(RETH9).deposit{value: 20 ether}();

        IERC20(USDB).approve(RUSD9, type(uint256).max);
        IRUSD(RUSD9).deposit(10 ether);

        getToken(tokenNum);
        vm.stopPrank();
    }

    /* FUNCTION */
    /* ENV CONFIG */
    function getINIT_CODEJson() internal view {
        bytes memory bytecode = abi.encodePacked(vm.getCode("OutswapV1Pair.sol:OutswapV1Pair"));
        console2.logBytes32(keccak256(bytecode));
    }

    function deployNewEnv() internal {
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

    function getToken(uint256 tokenNumber) internal {
        for (uint256 i = 0; i < tokenNumber; i++) {
            address token = address(new TestERC20(type(uint256).max / 2));
            tokens.push(token);
            safeApprove(token, address(swapRouter), type(uint256).max / 2);
        }
    }

    /* ADD LIQUIDTY */
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
        (tokenA, tokenB, amount0, amount1) =
            tokenA < tokenB ? (tokenA, tokenB, amount0, amount1) : (tokenB, tokenA, amount1, amount0);

        return IOutswapV1Router(router).addLiquidity(
            tokenA, tokenB, amount0, amount1, 0, 0, deployer, block.timestamp + 1 days
        );
    }

    function addLiquidityTokenAndUSDB(address token, uint256 tokenAmount, uint256 usdbAmount, address recipet) internal virtual returns (uint256 amount0, uint256 amount1, uint256 liquidity, address pair) {
        (address _token0, address _token1) = OutswapV1Library.sortTokens(token, RUSD9);
        pair = OutswapV1Library.pairFor(
            address(poolFactory),
            _token0,
            _token1
        );

        vm.startPrank(deployer);

        IERC20(USDB).approve(address(swapRouter), usdbAmount);
        if(token != RETH9) {
            IERC20(tokens[0]).approve(address(swapRouter), tokenAmount);
            (amount0, amount1, liquidity) = swapRouter.addLiquidityUSDB(
                tokens[0],
                tokenAmount,
                usdbAmount,
                tokenAmount,
                usdbAmount,
                recipet,
                block.timestamp + 1
            );
        }
        else {
            (amount0, amount1, liquidity) = swapRouter.addLiquidityETHAndUSDB{value: tokenAmount}(
                usdbAmount,
                tokenAmount,
                usdbAmount,
                recipet,
                block.timestamp + 1
            );
        }

        assertEq(poolFactory.getPair(_token0, _token1), pair);
        vm.stopPrank();
    }

    /* REMOVE LIQUIDITY */
    function removeLiquidityTokenAndUSDB(address token, uint256 amount, address recipet) internal virtual {
        (address _token0, address _token1) = OutswapV1Library.sortTokens(token, RUSD9);
        address pair = OutswapV1Library.pairFor(address(poolFactory), _token0, _token1 );

        IERC20(pair).approve(address(swapRouter), amount);
        if(token != RETH9) {
            swapRouter.removeLiquidityUSDB(
                tokens[0],
                amount,
                0,
                0,
                recipet,
                block.timestamp + 1
            );
        }
        else {
            swapRouter.removeLiquidityETHAndUSDB(
                amount,
                0,
                0,
                recipet,
                block.timestamp + 1
            );
        }

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
