pragma solidity 0.6.12;
import './ISwapper.sol';
interface ICauldron {
    function userCollateralShare(address user) external view returns(uint256);
     function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) external ;
    
    function userBorrowPart(address user) external view returns(uint256);
     
}