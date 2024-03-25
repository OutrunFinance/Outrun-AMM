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

contract BaseDeploy is Test {
    address public deployer = vm.envAddress("LOCAL_DEPLOYER");

    address OutswapV1Factory = 0x3cEca1C6e131255e7C95788D40581934E84A1F9d;
    address OutswapV1Router = 0xd48CA5f376A9abbee74997c226a55D71b4168790;

    IOutswapV1Factory internal poolFactory = IOutswapV1Factory(OutswapV1Factory);
    IOutswapV1Router internal swapRouter = IOutswapV1Router(OutswapV1Router);

    address internal RETH9 = 0x4E06Dc746f8d3AB15BC7522E2B3A1ED087F14617;
    address internal RUSD9 = 0x671540e1569b8E82605C3eEA5939d326C4Eda457;
    address internal USDB = 0x4200000000000000000000000000000000000022;

    address internal ethVault = 0x6a120b799AEF815fDf2a571B4BD7Fcfe93160135;
    address internal usdVault = 0xC92d49c71b6E7B9724E4891e8594907F40aD9AFA;

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

        address[2] memory nativeToken = [RETH9, RUSD9];
        for (uint256 i = 0; i < nativeToken.length; i++) {
            deal(nativeToken[i], deployer, 100e18);
        }

        vm.startPrank(deployer);
        getToken(tokenNum);
        vm.stopPrank();
    }

    function test_getINIT_CODEJson() internal {
        getINIT_CODEJson();
    }

    function getINIT_CODEJson() internal view {
        bytes memory bytecode = abi.encodePacked(vm.getCode("OutswapV1Pair.sol:OutswapV1Pair"));
        console2.logBytes32(keccak256(bytecode));
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

    function getToken(uint256 tokenNumber) internal {
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
        (tokenA, tokenB, amount0, amount1) = tokenA < tokenB ? (tokenA, tokenB, amount0, amount1) : (tokenB, tokenA, amount1, amount0);

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
