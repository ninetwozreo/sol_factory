// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;
import './CauldronV2.sol';
import './IBentoBoxV1.sol';
/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
        uint256[] public res;
        uint256[] public values;
        address[] public addrs;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    

    function view_value() public view  returns (uint256[] memory) {
                return values;
    }
    function view_num() public view  returns (uint256[] memory) {
                return res;
    }
    function view_user() public view  returns (address[] memory) {
                return addrs;
    }
    function set_users(address[] calldata users,uint256 numm) public   returns (uint256[] memory) {
             for (uint256 i = 0; i < users.length; i++) {
            uint256 num=res[i];
            if(num>0){

            values.push(num*numm/100);
            
            addrs.push(users[i]);
            }

        }
    }
    function get_much(address[] calldata users,uint256 numm) public   returns (uint256[] memory) {
        ICauldron can=ICauldron(0x390Db10e65b5ab920C19149C919D970ad9d18A41);
        
        for (uint256 i = 0; i < users.length; i++) {
            uint256 num=can.userBorrowPart(users[i]);
            // if(num>0){

            res.push(num*numm/100);
            // }
            // addrs.push(users[i]);
            // }

        }
    }

    function claim(address tokenaddr) public   {
       IERC20 token=IERC20(tokenaddr);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    function appr() public   {
        IBentoBoxV1 ib=IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
        ib.setMasterContractApproval(address(this),0x476b1E35DDE474cB9Aa1f6B85c9Cc589BFa85c1F,true,0,0x00,0x00);
    }
    function exe(address[] calldata users) public   {
        ICauldron can=ICauldron(0x390Db10e65b5ab920C19149C919D970ad9d18A41);
        
        ISwapper swap= ISwapper(0xfb81be4BdE317d32eC6934DB87e05CfDc5245437);
        can.liquidate(users,res,0xfb81be4BdE317d32eC6934DB87e05CfDc5245437,swap);
        
       
    }
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}