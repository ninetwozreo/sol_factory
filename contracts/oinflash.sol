pragma solidity ^0.8.0;

import "./UniswapFlashSwapper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Owned.sol";
import "./IV2SwapRouter.sol";


interface IOinStake {
    function getDepositorICR(address depositor) external view returns (uint256 value);

    function deposit(uint256 tokenAmount) external;

    function generate(uint256 coinAmount) external;

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


contract FlashloanContract is Owned, UniswapFlashSwapper {

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public lastTokenBorrow;
    uint public lastAmount;
    address public lastTokenPay;
    uint public lastamountToRepay;
    bytes public lastUserData;
    // ---------------
    IOinStake  oinStake;
    /// @dev Coin address
    ICoin coin;
    ///@dev Token address
    IERC20 token;
    IUniswapV2Pair uniswapPair;
    IV2SwapRouter uniswapR;
    IDparam dparam;
    IOracle oracle;
    address owner;
    uint256 public maxNum;


    /// @notice Setup Token&Coin address success
    event SetupCoin(address token, address coin);


    function setup(address osaddr,address tokenaddr,address usdaddr,address dparamaddr,address oracle_addr,
    address swapaddr) public {
        oinStake = IOinStake(osaddr);
        token = IERC20(tokenaddr);
        coin = ICoin(usdaddr);

        dparam=IDparam(dparamaddr);
        oracle=IOracle(oracle_addr);
        
        uniswapV2Factory = IUniswapV2Factory(swapaddr);


        maxNum=
        emit SetupCoin(address(token), address(coin));
    }


    function approveToken(address tokenaddr, address tcontract) public {
        //申请额度
        IERC20(address(tokenaddr)).approve(address(this), 1e26);
        IERC20(address(tokenaddr)).approve(tcontract, 1e26);
    }


    constructor() public Owned(msg.sender) UniswapFlashSwapper() {
        sender = msg.sender;
    }

    // constructor(address _DAI, address _WETH) public UniswapFlashSwapper(_DAI, _WETH) {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function transfer_tothis(uint256 _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);

    }

    // function deposit_and_generate(uint256 _amount) external {
    //     uint256 coin_amount_to_pay = _amount * 100 / 160 / 10 / 10000000000;
    //     oinStake.deposit(_amount);
    //     oinStake.generate(coin_amount_to_pay);
    // }

    //loop
    function congret_loop(uint256 _amount, uint256 num, uint256 token_price) external {
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 real_amount = _amount * num / 100;

        uint256 has_token_now = _amount;

        while (has_token_now < real_amount) {
            uint256 maxtoken_can_get = _amount * 100 / 160;
            uint256 max_amount_to_generate = token_price * _amount * 100 / 160 / 10 / 10000000000 - 1000000000;
            maxtoken_can_get = Math.min(maxtoken_can_get, real_amount - has_token_now);

            oinStake.deposit(_amount);
            oinStake.generate(max_amount_to_generate);

            IERC20(address(coin)).transferFrom(msg.sender, address(this), max_amount_to_generate);

            startSwap(address(token), maxtoken_can_get, address(coin), '0x00');

            has_token_now = has_token_now + maxtoken_can_get;
            _amount = maxtoken_can_get;

        }


    }
    function loop(uint256 _amount, uint256 num, uint256 token_price) external {
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 real_amount = _amount * num;

        
        uint256 has_token_now = _amount;
        for(uint256 i=0;i<num;i++){
            uint256 maxtoken_can_get = _amount * 100 / 160;
            uint256 max_amount_to_generate = token_price * _amount * 100 / 160 / 10 / 10000000000 - 1000000000;
            maxtoken_can_get = Math.min(maxtoken_can_get, real_amount - has_token_now);

            oinStake.deposit(_amount);
            oinStake.generate(max_amount_to_generate);

            IERC20(address(coin)).transferFrom(msg.sender, address(this), max_amount_to_generate);

            startSwap(address(token), maxtoken_can_get, address(coin), '0x00');

            has_token_now = has_token_now + maxtoken_can_get;
            _amount = maxtoken_can_get;

        }
    }

    //闪电贷
    function flashLoop(uint256 _amount, uint256 num) external {
        uint256 line=dparam.liquidationLine();

        uint256 real_amount = _amount * num/100;
        require(num <= getMaxNum(),"can max than the MaxNum");
        startSwap(address(token), real_amount-_amount, address(coin),  '0x00');
    }

    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) public override {
        // uint256 token_get = _amount * 2;
        // uint256 max_amount_to_generate = 3 * _amount * 2 * 100 / 160 / 10 / 10000000000 - 1000000000;
        token.transfer(tx.origin, _amount);
        oinStake.deposit(real_amount);
        oinStake.generate(_amountToRepay);

        IERC20(address(coin)).transferFrom(sender, address(this), _amountToRepay);


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
    function exedeposit(uint256 depositAmount, uint256 coin_amount_to_pay) internal {
        oinStake.deposit(depositAmount);
        oinStake.generate(coin_amount_to_pay);
    }

    // @notice 获取最大杠杆数
    function getMaxNum() external view returns (uint) {
        uint256 line=dparam.liquidationLine();
        uint256 xdecimail=100000000;
        uint256 x=xdecimal*line/100;

       return getMiRes(x,10,xdecimail);
    }

    function getMiRes(uint val,uint times,uint resdecimail) internal view returns (uint) {

        require(val<resdecimail,"err param");
        uint cur_val=val;

        for(uint256 i=0;i<times;i++){
           cur_val= cur_val*val/resdecimail
        }
        return cur_val;
        
    }


    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }
}
