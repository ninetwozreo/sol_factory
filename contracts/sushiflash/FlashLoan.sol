pragma solidity ^0.8.0;

import "./UniswapFlashSwapper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IV2SwapRouter.sol";


interface TqTokenInterface{}
interface TqErc20Interface{

    

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, TqTokenInterface tqTokenCollateral) external returns (uint);
    // function sweepToken(EIP20NonStandardInterface token) external;


    

    function _addReserves(uint addAmount) external returns (uint);
}



contract FlashloanContract is UniswapFlashSwapper {





    address tranquil_addr;
    address c_borrower;

    event SetupCoin(address token, address coin);


    function setup(address _tranquil_addr,address uniaddr) public {
        tranquil_addr = _tranquil_addr;
        uniswapV2Factory = IUniswapV2Factory(uniaddr);
        // emit SetupCoin(address(token), address(coin));
    }


    function approveToken(address tokenaddr, address tcontract) public {
        //申请额度
        IERC20(address(tokenaddr)).approve(address(this), 1e26);
        IERC20(address(tokenaddr)).approve(tcontract, 1e26);
    }

    function withdraw(address tokenaddr, address tcontract) public {

        //申请额度
        IERC20(address(tokenaddr)).transfer(msg.sender, IERC20(address(tokenaddr)).balanceOf(address(this)));
        IERC20(address(tokenaddr)).transferFrom(tcontract,msg.sender, IERC20(address(tokenaddr)).balanceOf(address(tcontract)));
        // IERC20(address(tokenaddr)).approve(tcontract, 1e26);
    }


    constructor()UniswapFlashSwapper() {
        // sender = msg.sender;
    }

    

    //闪电贷
    function action(address token_loan,uint256 loan_amount,address token_pay,address borrower) external {

        c_borrower=borrower;
        startSwap(token_loan, loan_amount, token_pay, '0x00');
    }

    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) public override {
        TqErc20Interface tq=TqErc20Interface(tranquil_addr);
        tq.liquidateBorrow(c_borrower,_amount,TqTokenInterface(tranquil_addr));

        tq.redeem(IERC20(tranquil_addr).balanceOf(address(this)));
        


        uint256 _amount_get=IERC20(_tokenPay).balanceOf(address(this))- _amountToRepay;
        IERC20(_tokenPay).transfer(tx.origin, _amount_get);
        
        // oinStake.liqudate(tx.origin);
        // IERC20(address(coin)).transferFrom(tx.origin, address(this), _amountToRepay);


    }

   

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }
}
