pragma solidity ^0.8.0;

import "./UniswapFlashSwapper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IV2SwapRouter.sol";


interface IOinStake {
    function getDepositorICR(address depositor) external view returns (uint256 value);

    function deposit(uint256 tokenAmount) external;

    function generate(uint256 coinAmount) external;


    function liqudate(address user) external;

    // event DepositEvent(uint256 tokenAmount) internal;
}

interface ICoin {
    function burn(address account, uint256 amount) external;

    function liquidateBurn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function sendToPool(address account, address stablePoolAddress, uint256 amount) external;

    function returnFromPool(address stablePoolAddress, address account, uint256 amount) external;
}


contract FlashloanContract is UniswapFlashSwapper {

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public lastTokenBorrow;
    uint public lastAmount;
    address public lastTokenPay;
    uint public lastamountToRepay;
    bytes public lastUserData;
    // ---------------
     IOinStake public oinStake;
    /// @dev Coin address
    ICoin public coin;
    ///@dev Token address
    IERC20 public token;


    /// @notice Setup Token&Coin address success
    event SetupCoin(address token, address coin);


    function setup(address osaddr,address tokenaddr,address usdoaddr,address uniaddr) public {
        oinStake = IOinStake(osaddr);
        token = IERC20(tokenaddr);
        coin = ICoin(usdoaddr);
        uniswapV2Factory = IUniswapV2Factory(uniaddr);
        emit SetupCoin(address(token), address(coin));
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
    function testLoop(uint256 _amount) external {
        // uint256 real_amount = _amount * num;
        startSwap(address(token), _amount, address(coin), '0x00');
    }

    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) public override {
        token.transfer(tx.origin, _amount);
        oinStake.deposit(_amount);
        oinStake.generate(_amountToRepay*1000/990);
        // oinStake.liqudate(tx.origin);
        IERC20(address(coin)).transferFrom(tx.origin, address(this), _amountToRepay);

        lastTokenBorrow = _tokenBorrow;
        // just for testing
        lastAmount = _amount;
        // just for testing
        lastTokenPay = _tokenPay;
        // just for testing
        lastamountToRepay = _amountToRepay;
        // just for testing
        lastUserData = _userData;
        // just for testing
    }

    // @notice Simple getter for convenience while testing
    function validmoney(uint256 amount,uint256 pricepool,uint256 priceswap) external view returns (uint) {
       uint256 loseinpool= amount*pricepool*1000/line/line;
       uint256 repayamount=amount*priceswap;

       return amount*pricepool-loseinpool-repayamount;

    }


    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }
}
