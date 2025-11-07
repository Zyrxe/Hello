// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ALONEAToken is Initializable, ERC20Upgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    address public buybackWallet;
    address public liquidityWallet;
    address public treasuryWallet;
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 10**18;
    uint256 public constant FEE_PERCENT = 200; // 2% in basis points
    uint256 public constant BUYBACK_PERCENT = 100; // 1%
    uint256 public constant LIQUIDITY_PERCENT = 50; // 0.5%
    uint256 public constant TREASURY_PERCENT = 50; // 0.5%
    
    mapping(address => bool) private _isExcludedFromFee;
    
    event FeesDistributed(uint256 buybackAmount, uint256 liquidityAmount, uint256 treasuryAmount);
    event TokensBurned(address indexed burner, uint256 amount);

    function initialize(
        address initialOwner,
        address _buybackWallet,
        address _liquidityWallet,
        address _treasuryWallet
    ) public initializer {
        __ERC20_init("ALONEA", "ALO");
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        
        buybackWallet = _buybackWallet;
        liquidityWallet = _liquidityWallet;
        treasuryWallet = _treasuryWallet;
        
        _isExcludedFromFee[initialOwner] = true;
        _isExcludedFromFee[_buybackWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = true;
        _isExcludedFromFee[_treasuryWallet] = true;
        
        _mint(initialOwner, TOTAL_SUPPLY);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override nonReentrant {
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 fees = (amount * FEE_PERCENT) / 10000;
            uint256 transferAmount = amount - fees;
            
            if (fees > 0) {
                uint256 buybackFee = (fees * BUYBACK_PERCENT) / FEE_PERCENT;
                uint256 liquidityFee = (fees * LIQUIDITY_PERCENT) / FEE_PERCENT;
                uint256 treasuryFee = (fees * TREASURY_PERCENT) / FEE_PERCENT;
                
                super._transfer(from, buybackWallet, buybackFee);
                super._transfer(from, liquidityWallet, liquidityFee);
                super._transfer(from, treasuryWallet, treasuryFee);
                
                emit FeesDistributed(buybackFee, liquidityFee, treasuryFee);
            }
            
            super._transfer(from, to, transferAmount);
        }
    }

    function excludeFromFee(address account, bool excluded) external onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
        emit TokensBurned(_msgSender(), amount);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
}
