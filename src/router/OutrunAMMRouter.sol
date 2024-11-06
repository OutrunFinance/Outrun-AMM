//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOutrunAMMRouter} from "./interfaces/IOutrunAMMRouter.sol";
import {IWETH} from "../libraries/IWETH.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {IOutrunAMMPair, OutrunAMMLibrary} from "../libraries/OutrunAMMLibrary.sol";
import {IOutrunAMMERC20} from "../core/interfaces/IOutrunAMMERC20.sol";
import {IOutrunAMMFactory} from "../core/interfaces/IOutrunAMMFactory.sol";

contract OutrunAMMRouter is IOutrunAMMRouter {
    address public immutable factory;
    address public immutable WETH;
    uint256 public immutable swapFeeRate;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, Expired());
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        swapFeeRate = IOutrunAMMFactory(_factory).swapFeeRate();
    }

    receive() external payable {
        // only accept ETH via fallback from the WETH contract
        require(msg.sender == WETH, InvaildETHSender());
    }

    /**
     * ADD LIQUIDITY *
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IOutrunAMMFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IOutrunAMMFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = OutrunAMMLibrary.getReserves(factory, tokenA, tokenB, swapFeeRate);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = OutrunAMMLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, InsufficientBAmount());
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = OutrunAMMLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, InsufficientAAmount());
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = OutrunAMMLibrary.pairFor(factory, tokenA, tokenB, swapFeeRate);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IOutrunAMMPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        (amountToken, amountETH) = _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = OutrunAMMLibrary.pairFor(factory, token, WETH, swapFeeRate);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IOutrunAMMPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = OutrunAMMLibrary.pairFor(factory, tokenA, tokenB, swapFeeRate);
        IOutrunAMMERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IOutrunAMMPair(pair).burn(to);
        (address token0,) = OutrunAMMLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, InsufficientAAmount());
        require(amountB >= amountBMin, InsufficientBAmount());
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * REMOVE LIQUIDITY (supporting fee-on-transfer tokens) *
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * SWAP *
     */
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to, address referrer) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = OutrunAMMLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? OutrunAMMLibrary.pairFor(factory, output, path[i + 2], swapFeeRate) : _to;
            IOutrunAMMPair(OutrunAMMLibrary.pairFor(factory, input, output, swapFeeRate)).swap(
                amount0Out, amount1Out, to, referrer, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = OutrunAMMLibrary.getAmountsOut(factory, amountIn, path, swapFeeRate);
        require(amounts[amounts.length - 1] >= amountOutMin, InsufficientOutputAmount());
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]
        );
        _swap(amounts, path, to, referrer);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = OutrunAMMLibrary.getAmountsIn(factory, amountOut, path, swapFeeRate);
        require(amounts[0] <= amountInMax, ExcessiveInputAmount());
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]
        );
        _swap(amounts, path, to, referrer);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin, 
        address[] calldata path, 
        address to,
        address referrer,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, InvalidPath());
        amounts = OutrunAMMLibrary.getAmountsOut(factory, msg.value, path, swapFeeRate);
        require(amounts[amounts.length - 1] >= amountOutMin, InsufficientOutputAmount());
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]));
        _swap(amounts, path, to, referrer);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, InvalidPath());
        amounts = OutrunAMMLibrary.getAmountsIn(factory, amountOut, path, swapFeeRate);
        require(amounts[0] <= amountInMax, ExcessiveInputAmount());
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]
        );
        _swap(amounts, path, address(this), referrer);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, InvalidPath());
        amounts = OutrunAMMLibrary.getAmountsOut(factory, amountIn, path, swapFeeRate);
        require(amounts[amounts.length - 1] >= amountOutMin, InsufficientOutputAmount());
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]
        );
        _swap(amounts, path, address(this), referrer);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut, 
        address[] calldata path, 
        address to,
        address referrer,
        uint256 deadline
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, InvalidPath());
        amounts = OutrunAMMLibrary.getAmountsIn(factory, amountOut, path, swapFeeRate);
        require(amounts[0] <= msg.value, ExcessiveInputAmount());
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amounts[0]));
        _swap(amounts, path, to, referrer);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /**
     * SWAP (supporting fee-on-transfer tokens) *
     */
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, address referrer) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = OutrunAMMLibrary.sortTokens(input, output);
            IOutrunAMMPair pair = IOutrunAMMPair(OutrunAMMLibrary.pairFor(factory, input, output, swapFeeRate));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = OutrunAMMLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, swapFeeRate);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? OutrunAMMLibrary.pairFor(factory, output, path[i + 2], swapFeeRate) : _to;
            pair.swap(amount0Out, amount1Out, to, referrer, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, referrer);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            InsufficientOutputAmount()
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, InvalidPath());
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, referrer);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            InsufficientOutputAmount()
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, InvalidPath());
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, OutrunAMMLibrary.pairFor(factory, path[0], path[1], swapFeeRate), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), referrer);
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, InsufficientOutputAmount());
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA, 
        uint256 reserveA, 
        uint256 reserveB
    ) public view virtual override returns (uint256 amountB) {
        return OutrunAMMLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut
    ) public view virtual override returns (uint256 amountOut) {
        return OutrunAMMLibrary.getAmountOut(amountIn, reserveIn, reserveOut, swapFeeRate);
    }

    function getAmountIn(
        uint256 amountOut, 
        uint256 reserveIn, 
        uint256 reserveOut
    ) public view virtual override returns (uint256 amountIn) {
        return OutrunAMMLibrary.getAmountIn(amountOut, reserveIn, reserveOut, swapFeeRate);
    }

    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return OutrunAMMLibrary.getAmountsOut(factory, amountIn, path, swapFeeRate);
    }

    function getAmountsIn(
        uint256 amountOut, 
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return OutrunAMMLibrary.getAmountsIn(factory, amountOut, path, swapFeeRate);
    }
}
