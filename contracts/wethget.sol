pragma solidity >=0.6.6 <0.9.0;

import "./weth.sol";


interface WETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
    function transfer(address dst , uint256 wad) external;

    event Transfer(address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

contract WETHSwap {


   address WETH9_Address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

//先转账给合约 
   function depositWETH( uint256 _amount) external {
       (bool success, ) = address(address(this)).call{value: _amount}("");
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
       WETH(WETH9_Address).deposit{value: _amount}();
    }



    function withdrawWETH( uint256 _amount) external {
       WETH(WETH9_Address).withdraw(_amount);
    //    WETH(_tokenBorrow).withdraw(_amount);

    //    WETH(_tokenBorrow).transfer(msg.sender,_amount);
        //    WETH(_tokenBorrow).deposit{value: _amount}();
        //    WETH(_tokenBorrow).deposit {_amount, gas:4000000}();
    }

      function transferWETH(uint256 _amount) external {
       WETH(WETH9_Address).transfer(msg.sender,_amount);
    }
    
 receive() payable external{}
}
