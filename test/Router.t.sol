// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// import "forge-std/console.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {IOutrunAMMPair} from "../src/core/interfaces/IOutrunAMMPair.sol";
// import {IOutrunAMMRouter, OutrunAMMRouter} from "../src/router/OutrunAMMRouter.sol";

// contract RouterTest is Test {
//     address jason = makeAddr("jason");
//     address routerAddress = 0x7d26F6Dd2D7f1E30f4C1562117FFC4349335e3EE;
//     address pairAddress = 0xe4d4972eD1836FAe83544745CEe1D4dB454c4468;
//     address[] path;

//     IOutrunAMMRouter router;
//     IOutrunAMMPair pair;

//     function setUp() public {
//         router = IOutrunAMMRouter(routerAddress);
//         pair = IOutrunAMMPair(pairAddress);
//         deal(jason, 1 ether);

        
//         path.push(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
//         path.push(0xCc752dC4ae72386986d011c2B485be0DAd98C744);
//     }

//     function test_swap() public {
//         vm.startPrank(jason);
//         router.swapExactETHForTokens{value: 0.0001 ether}(
//             0, 
//             path, 
//             jason, 
//             0x0000000000000000000000000000000000000000, 
//             1742497320
//         );

//         assertNotEq(address(jason).balance, 1 ether);
//     }
// }