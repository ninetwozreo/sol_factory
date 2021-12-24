pragma solidity >=0.5.0 <0.9.0;
import "./UniswapV3Interfaces.sol";
import "./UniswapV2Interfaces.sol";

contract main{
    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // same for all networks
    IUniswapV3Factory constant uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984); // same for all networks

    constructor(address _DAI, address _WETH) public {
        WETH = _WETH;
        DAI = _DAI;
    }

    function startSwap(address _tokenBorrow, uint256 _amount, address _tokenPay) internal {
        bytes memory _userData='';
        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        // if (tokenBorrow == ETH) {
        //     isBorrowingEth = true;
        //     tokenBorrow = WETH; // we'll borrow WETH from UniswapV2 but then unwrap it for the user
        // }
        // if (tokenPay == ETH) {
        //     isPayingEth = true;
        //     tokenPay = WETH; // we'll wrap the user's ETH before sending it back to UniswapV2
        // }

        // if (tokenBorrow == tokenPay) {
        //     simpleFlashLoan(tokenBorrow, _amount, isBorrowingEth, isPayingEth, _userData);
        //     return;
        // } else if (tokenBorrow == WETH || tokenPay == WETH) {
        //     simpleFlashSwap(tokenBorrow, _amount, tokenPay, isBorrowingEth, isPayingEth, _userData);
        //     return;
        // } else {
        //     traingularFlashSwap(tokenBorrow, _amount, tokenPay, _userData);
        //     return;
        // }

    }
}
