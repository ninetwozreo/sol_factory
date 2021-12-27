pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./Owned.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
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



contract FlashLoan is Owned {

    IOinStake public oinStake;
    /// @dev Coin address
    ICoin coin;
    ///@dev Token address
    IERC20 token;
    IUniswapV2Pair uniswap;

    /// @notice Setup Token&Coin address success
    event SetupCoin(address token, address coin);


    constructor() public Owned(msg.sender)  {
        
    }

    function setup(address _uniswap, address _oinStake,address _token, address _coin) public  {
        uniswap = IUniswapV2Pair(_uniswap);
        oinStake = IOinStake(_oinStake);
        require(address(token) == address(0) && address(coin) == address(0), "Token address already set up.");
        token = IERC20(_token);
        coin = ICoin(_coin);
        emit SetupCoin(_token, _coin);
    }


    function Init() public {
        //申请额度
      token.approve(address(oinStake), 1e26);
      token.approve(address(uniswap), 1e26);
      
    }

    //TODO 循环借贷 然后去swap后再次借贷
    function flashLoan(uint256 loopAmount,uint256 amount,uint256 coinAmount) public {
        //申请额度
       token.approve(address(oinStake), 1e26);
         for (uint256 i = 0; i < loopAmount; i++) {
             require(amount > 0, "Amount must be non-zero");
            oinStake.deposit(amount);
     
            oinStake.generate(coinAmount);
            //计算出amount0 amount1
            // uniswap.swap(coinAmount,amount,msg.sender,'');
        }
    }




}