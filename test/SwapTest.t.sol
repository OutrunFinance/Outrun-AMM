//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IOutrunAMMRouter} from "src/router/interfaces/IOutrunAMMRouter.sol";

contract SwapTest is Test {
    address internal sender;
    address internal orETH;
    address internal orUSD;
    IOutrunAMMRouter internal swapRouter;

    function setUp() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        sender = vm.rememberKey(privateKey);

        address OutrunAMMRouter = 0x4d821974783d88E4996241EcbBf62935180941a8;
        orETH = 0xF62f5dB01cb60d80219F478D5CDffB6398Cee9A5;
        orUSD = 0xe04b19ed724A328C804e82e7196dcef18570bfae;
        swapRouter = IOutrunAMMRouter(OutrunAMMRouter);
        vm.startBroadcast(sender);
        vm.stopBroadcast();
    }

    function test_swapExactETHForUSDB() public {
        vm.startBroadcast(sender);
        address[] memory path;
        path = new address[](2);
        path[0] = orETH;
        path[1] = orUSD;
        uint256[] memory amounts = swapRouter.swapExactETHForUSDB{value: 10000000000000}(0x193529efd49863c, path, 0xcae21365145C467F8957607aE364fb29Ee073209, 0x66671c08);
        console2.log("Swap ETH to USDB:", amounts[0], "-", amounts[1]);
        vm.stopBroadcast();
    }
}

    
    