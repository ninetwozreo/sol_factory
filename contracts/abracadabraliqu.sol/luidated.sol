pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// import "./Math.sol";
// import "./SafeMath.sol";
// import "./Owned.sol";
// import "./IERC20.sol";
// import "./IUniswapV2Pair.sol";
// import "./IV2SwapRouter.sol";



contract  abracsolent {
    // using RebaseLibrary for Rebase;
    //=ICauldronV2(0x390Db10e65b5ab920C19149C919D970ad9d18A41)
    ICauldronV2 cadv2 ;
    IBentoBoxV1 bentoBox;
    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5;
    uint256 private constant COLLATERIZATION_RATE = 90000;
    
// function view_user() public view  returns (address[] memory) {

    function setup(address can,address bento) external{
        cadv2 =ICauldronV2(can);
        bentoBox==IBentoBoxV1(bento);
    }

    function filter(address[] calldata userr, uint256 _exchangeRate,uint128 elastic,uint128 base,uint256 c_rate) public view  returns (address[] memory) {
        address[] memory users=userr;
        // address[] res;

        for (uint256 i = 0; i < users.length; i++) {
                address user=users[i];
            if(_isSolvent(user,_exchangeRate,elastic,base,c_rate)){
                delete users[i];
                // users.length--;
                // res.push()
            }
        }

        return users;
    }
function _isSolvent(address user, uint256 _exchangeRate,uint128 elastic,uint128 base,uint256 c_rate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart =cadv2.userBorrowPart(user);
        if (borrowPart == 0) return true;
        uint256 collateralShare = cadv2.userCollateralShare(user);
        if (collateralShare == 0) return false;

        return
            bentoBox.toAmount(
                IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
                collateralShare*(EXCHANGE_RATE_PRECISION *c_rate/COLLATERIZATION_RATE_PRECISION),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart*elastic*_exchangeRate/base;
    }
}



interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
interface IBentoBoxV1 {
    function balanceOf(IERC20 token, address user) external view returns (uint256 share);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface ICauldronV2 {


    
    function userBorrowPart(address user) external view returns (uint256 value);
    function userCollateralShare(address user) external view returns (uint256 value);

}

//      // Immutables (for MasterContract and all clones)
//      IBentoBoxV1 public immutable bentoBox;
//      IERC20 public immutable magicInternetMoney;
 
//      // MasterContract variables
//      address public feeTo;
 
//      // Per clone variables
//      // Clone init settings
//      IERC20 public collateral;
//      bytes public oracleData;
//      struct Rebase {
//         uint128 elastic;
//         uint128 base;
//     }
//      // Total amounts
//      uint256 public totalCollateralShare; // Total collateral supplied
//      Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
 
//      // User balances
//      mapping(address => uint256) public userCollateralShare;
//      mapping(address => uint256) public userBorrowPart;
 
//      /// @notice Exchange and interest rate tracking.
//      /// This is 'cached' here because calls to Oracles can be very expensive.
//      uint256 public exchangeRate;
 
//      struct AccrueInfo {
//          uint64 lastAccrued;
//          uint128 feesEarned;
//          uint64 INTEREST_PER_SECOND;
//      }
 
//      AccrueInfo public accrueInfo;
// }

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}
// library RebaseLibrary {
//     using BoringMath128 for uint128;

//     struct Rebase {
//         uint128 elastic;
//         uint128 base;
//     }
//     /// @notice Calculates the base value in relationship to `elastic` and `total`.
//     function toBase(
//         Rebase memory total,
//         uint256 elastic,
//         bool roundUp
//     ) internal pure returns (uint256 base) {
//         if (total.elastic == 0) {
//             base = elastic;
//         } else {
//             base = elastic.mul(total.base) / total.elastic;
//             if (roundUp && base.mul(total.elastic) / total.base < elastic) {
//                 base = base.add(1);
//             }
//         }
//     }

//     /// @notice Calculates the elastic value in relationship to `base` and `total`.
//     function toElastic(
//         Rebase memory total,
//         uint256 base,
//         bool roundUp
//     ) internal pure returns (uint256 elastic) {
//         if (total.base == 0) {
//             elastic = base;
//         } else {
//             elastic = base.mul(total.elastic) / total.base;
//             if (roundUp && elastic.mul(total.base) / total.elastic < base) {
//                 elastic = elastic.add(1);
//             }
//         }
//     }

//     /// @notice Add `elastic` to `total` and doubles `total.base`.
//     /// @return (Rebase) The new total.
//     /// @return base in relationship to `elastic`.
//     function add(
//         Rebase memory total,
//         uint256 elastic,
//         bool roundUp
//     ) internal pure returns (Rebase memory, uint256 base) {
//         base = toBase(total, elastic, roundUp);
//         total.elastic = total.elastic.add(elastic.to128());
//         total.base = total.base.add(base.to128());
//         return (total, base);
//     }

//     /// @notice Sub `base` from `total` and update `total.elastic`.
//     /// @return (Rebase) The new total.
//     /// @return elastic in relationship to `base`.
//     function sub(
//         Rebase memory total,
//         uint256 base,
//         bool roundUp
//     ) internal pure returns (Rebase memory, uint256 elastic) {
//         elastic = toElastic(total, base, roundUp);
//         total.elastic = total.elastic.sub(elastic.to128());
//         total.base = total.base.sub(base.to128());
//         return (total, elastic);
//     }

//     /// @notice Add `elastic` and `base` to `total`.
//     function add(
//         Rebase memory total,
//         uint256 elastic,
//         uint256 base
//     ) internal pure returns (Rebase memory) {
//         total.elastic = total.elastic.add(elastic.to128());
//         total.base = total.base.add(base.to128());
//         return total;
//     }

//     /// @notice Subtract `elastic` and `base` to `total`.
//     function sub(
//         Rebase memory total,
//         uint256 elastic,
//         uint256 base
//     ) internal pure returns (Rebase memory) {
//         total.elastic = total.elastic.sub(elastic.to128());
//         total.base = total.base.sub(base.to128());
//         return total;
//     }

//     /// @notice Add `elastic` to `total` and update storage.
//     /// @return newElastic Returns updated `elastic`.
//     function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
//         newElastic = total.elastic = total.elastic.add(elastic.to128());
//     }

//     /// @notice Subtract `elastic` from `total` and update storage.
//     /// @return newElastic Returns updated `elastic`.
//     function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
//         newElastic = total.elastic = total.elastic.sub(elastic.to128());
//     }
// }


library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}
