pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./AlchemixGelatoKeeper.sol";
import "../interfaces/IAlchemistV2.sol";
import "../interfaces/keepers/IHarvestResolver.sol";
import "../interfaces/keepers/IAlchemixHarvesterOptimism.sol";
import "../interfaces/ISidecar.sol";

contract AlchemixHarvesterOptimism is IAlchemixHarvesterOptimism, AlchemixGelatoKeeper {
  /// @notice The address of the resolver.
  address public resolver;

  /// @notice The address of the sidecar.
  address public sidecar;

  constructor(
    address _gelatoPoker,
    uint256 _maxGasPrice,
    address _resolver,
    address _sidecar
  ) AlchemixGelatoKeeper(_gelatoPoker, _maxGasPrice) {
    resolver = _resolver;
    sidecar = _sidecar;
  }

  function setResolver(address _resolver) external onlyOwner {
    resolver = _resolver;
  }

  /// @notice Runs a the specified harvest job and donates optimism rewards.
  ///
  /// @param alchemist        The address of the target alchemist.
  /// @param yieldToken       The address of the target yield token.
  /// @param minimumAmountOut The minimum amount of tokens expected to be harvested.
  function harvest(
    address alchemist,
    address yieldToken,
    uint256 minimumAmountOut,
    uint256 expectedExchange
  ) external override {
    if (msg.sender != gelatoPoker) {
      revert Unauthorized();
    }
    if (tx.gasprice > maxGasPrice) {
      revert TheGasIsTooDamnHigh();
    }
    IAlchemistV2(alchemist).harvest(yieldToken, minimumAmountOut);

    // Claim and distribute optimism rewards
    address[] memory assets = new address[](1);
    assets[0] = address(yieldToken);
    ISidecar(sidecar).claimAndDistributeRewards(assets, expectedExchange);

    IHarvestResolver(resolver).recordHarvest(yieldToken);
  }
}
