//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IOutswapV1Pair.sol";
import "./interfaces/IOutswapV1Factory.sol";
import "./interfaces/IOutswapV1Callee.sol";
import "../libraries/UQ112x112.sol";
import "./OutswapV1ERC20.sol";

contract OutswapV1Pair is IOutswapV1Pair, OutswapV1ERC20 {
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    
    uint256 public accumFeePerLP;
    mapping(address account => uint256) public makerFeePerLP;
    mapping(address account => uint256) public pendingFees;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "OutswapV1: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        factory = msg.sender;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // view current maker fee of account
    function viewMakerFee(address account) external view override returns (uint256 _amount0, uint256 _amount1, address _token0, address _token1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); 
        uint256 _accumFeePerLP = accumFeePerLP + (Math.sqrt(uint256(_reserve0) * uint256(_reserve1)) - Math.sqrt(kLast)) / totalSupply;
        
        uint256 makerFeeLast = pendingFees[account];
        uint256 lpFee = balanceOf(account) * (_accumFeePerLP - makerFeeLast);
        uint256 makerFee;
        if (lpFee > 0) {
            makerFee = _feeTo() != address(0) ? makerFeeLast + lpFee * 3 / 4 : makerFeeLast + lpFee;
        }

        uint256 _totalSupply = totalSupply;
        _amount0 = makerFee * _reserve0 / _totalSupply; 
        _amount1 = makerFee * _reserve1 / _totalSupply;
        _token0 = token0;
        _token1 = token1;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "OutswapV1: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, "OutswapV1: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, to, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "OutswapV1: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "OutswapV1: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "OutswapV1: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "OutswapV1: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IOutswapV1Callee(to).OutswapV1Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "OutswapV1: INSUFFICIENT_INPUT_AMOUNT");

        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            require(
                balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * 1000 ** 2,
                "OutswapV1: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        {   
            uint256 k = uint256(reserve0) * uint256(reserve1);
            accumFeePerLP = _accumulate(Math.sqrt(k), Math.sqrt(kLast));
            kLast = k;
        }
        
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // claim maker fee
    function claimMakerFee() external override {
        address msgSender = msg.sender;
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        _mintFee(_reserve0, _reserve1);
        kLast = uint256(_reserve0) * uint256(_reserve1);

        uint256 makerFee = pendingFees[msgSender];
        if (makerFee > 0) {
            pendingFees[msgSender] = 0;
            _mint(msgSender, makerFee);
        }
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        _mintFee(_reserve0, _reserve1);
        kLast = uint256(_reserve0) * uint256(_reserve1);
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        _mintFee(_reserve0, _reserve1);
        kLast = uint256(_reserve0) * uint256(_reserve1);
        _transfer(from, to, value);
        return true;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "OutswapV1: TRANSFER_FAILED");
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "OutswapV1: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/4th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private {
        address feeTo = _feeTo();
        if (kLast != 0) {
            uint256 rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
            uint256 rootKLast = Math.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 _accumFeePerLP = accumFeePerLP;
                if (totalSupply != 0) {
                    _accumFeePerLP = accumFeePerLP + (rootK - rootKLast) / totalSupply;
                    accumFeePerLP = _accumFeePerLP;
                }

                address msgSender = msg.sender;
                uint256 lpFee = balanceOf(msgSender) * (_accumFeePerLP - makerFeePerLP[msgSender]);
                if (lpFee > 0) {
                    if (feeTo != address(0)) {
                        _mint(feeTo, lpFee / 4);
                        pendingFees[msgSender] += lpFee * 3 / 4;
                    } else {
                        pendingFees[msgSender] += lpFee;
                    }
                }
                makerFeePerLP[msgSender] = _accumFeePerLP;
            }
        }
    }

    function _accumulate(uint256 rootK, uint256 rootKLast) internal returns (uint256) {
        return accumFeePerLP + ((rootK - rootKLast) / totalSupply);
    }

    function _feeTo() view internal returns (address) {
        return IOutswapV1Factory(factory).feeTo();
    }
}
