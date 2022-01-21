pragma solidity 0.5.17;

import "./UniswapFlashSwapper.sol";

import "./Math.sol";
import "./SafeMath.sol";
import "./Owned.sol";
// import "./IERC20.sol";
// import "./IUniswapV2Pair.sol";
import "./IV2SwapRouter.sol";
// import "./UniswapFlashSwapper.sol";


interface IOinStake {
    function getDepositorICR(address depositor) external view returns (uint256 value);

    function deposit(uint256 tokenAmount) external;

    function generate(uint256 coinAmount) external;

    event DepositEvent(uint256 tokenAmount);
}

interface ICoin {
    function burn(address account, uint256 amount) external;

    function liquidateBurn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function sendToPool(address account, address stablePoolAddress, uint256 amount) external;

    function returnFromPool(address stablePoolAddress, address account, uint256 amount) external;
}

   


contract ExampleContract is UniswapFlashSwapper {

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public lastTokenBorrow;
    uint public lastAmount;
    address public lastTokenPay;
    uint public lastamountToRepay;
    bytes public lastUserData;
// ---------------
 IOinStake public oinStake;
    /// @dev Coin address
    ICoin coin;
    ///@dev Token address
    IERC20 token;
    IUniswapV2Pair uniswapPair;
    IV2SwapRouter uniswapR;

    /// @notice Setup Token&Coin address success
    event SetupCoin(address token, address coin);


   

    function setup(address _uniswap, address _oinStake,address _token) public  {
        uniswapPair = IUniswapV2Pair(_uniswap);
        uniswapR = IV2SwapRouter(_uniswap);
        oinStake = IOinStake(_oinStake);
        // require(address(token) == address(0) && address(coin) == address(0), "Token address already set up.");
        token = IERC20(_token);
        coin = ICoin(0x031CCaB6583B2a5ABBcC58E48e74E6acafE9c503);
        emit SetupCoin(address( token),address(coin));
    }


    function Init() public {
        //申请额度
      token.approve(address(oinStake), 1e26);
      token.approve(address(uniswapR), 1e26);
      token.approve(address(this), 1e26);
    //   token.approve(address(this), 1e26);

      IERC20(address(coin)).approve(address(this), 1e26);
      
    }
    
    function approveToken(address tokenaddr) public {
        //申请额度

      IERC20(address(tokenaddr)).approve(address(this), 1e26);
      IERC20(address(tokenaddr)).approve(address(uniswapR), 1e26);
      
    }

    //TODO 循环借贷 然后去swap后再次借贷
    function flashLoan(uint256 loopAmount,uint256 amount,uint256 coinAmount) public {
        //申请额度
       token.approve(address(oinStake), 1e26);

        address[] memory path = new address[](2);
            path[0] = address(token);
            path[1] = address(coin);
        uniswapR.swapExactTokensForTokens(uint256(1000000000000000000), uint256(0), path,msg.sender,uint256(1640504596));

         for (uint256 i = 0; i < loopAmount; i++) {
             require(amount > 0, "Amount must be non-zero");
            oinStake.deposit(amount);
     
            oinStake.generate(coinAmount);
            //计算出amount0 amount1
        }
    }


    constructor(address _DAI, address _WETH) public UniswapFlashSwapper(_DAI, _WETH) {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function testLoop( uint256 _amount,uint256 num,uint256 tokenPrice,bytes calldata _userData) external {
        uint256 real_amount=_amount*num;
        // token.transfer(msg.sender,token_amount_to_borrow);

        uint256 token_amount_to_borrow=real_amount-_amount;

        startSwap(address(token), token_amount_to_borrow,address(coin),_userData);
        
        token.transfer(msg.sender,token_amount_to_borrow);

        uint256 coin_amount_to_pay=  tokenPrice*token_amount_to_borrow*1004/1000/100000000/10000000000;
        oinStake.deposit(real_amount);
        oinStake.generate(coin_amount_to_pay);

        IERC20(address(coin)).transferFrom(msg.sender,address(this),coin_amount_to_pay);
        
        
    }

    function flashSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, uint256 _amountPay,bytes calldata _userData) external {
        // you can do anything you want to here before the flash swap happens
        // ...

        // //首先把钱打给合约 TODO

        IERC20(_tokenPay).transferFrom(msg.sender,address(this) ,_amountPay);
        // token.transferFrom(msg.sender,address(this),_amount);
        // IERC20(address(coin)).transferFrom(msg.sender,address(this),_amount*105/1000);

        // // 这里计算下他能铸造的usd
        // _amount=_amount*1625/1000;
        // uint256 _amountfromswap=_amount*625/1000;
        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` function below
        //这里borrow 应该是质押币，用usd去还
        startSwap(_tokenBorrow, _amount, _tokenPay, _userData);
        // startSwap(_tokenBorrow, _amountfromswap, _tokenPay, _userData);

        // token.transfer(msg.sender,_amount);
        IERC20(_tokenBorrow).transfer(msg.sender,_amount);

        
        // oinStake.deposit(_amount);
        
        // oinStake.generate(1003*_amount/10000);
        // // todo 把usdt打给合约
        // IERC20(address(coin)).transferFrom(msg.sender,address(this),1003*_amount/10000);

        // you can do anything you want to here after the flash swap has completed
        // ...
    }


    // @notice This is where your custom logic goes
    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically for you -- DO NOT pay back the loan in this function
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //        the flash-borrow when this function finishes executing
    // @param _userData Any data you privided to the flashBorrow function when you called it
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
        // do whatever you want here
        // we're just going to update some local variables because we're boring
        // but you could do some arbitrage or liquidaztions or CDP collateral swaps, etc

        lastTokenBorrow = _tokenBorrow; // just for testing
        lastAmount = _amount; // just for testing
        lastTokenPay = _tokenPay; // just for testing
        lastamountToRepay = _amountToRepay; // just for testing
        lastUserData = _userData; // just for testing
    }

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }
}
