/*
 * Copyright ©️ 2018 Galt•Project Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka)
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) by
 * [Basic Agreement](ipfs/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS)).
 */

pragma solidity ^0.5.13;

import "./IPGGMultiSig.sol";
import "./IPGGArbitratorStakeAccounting.sol";
import "./IPGGOracles.sol";
import "./IPGGOracleStakeAccounting.sol";
import "../voting/interfaces/IPGGMultiSigCandidateTop.sol";
import "../voting/interfaces/IPGGDelegateReputationVoting.sol";
import "../voting/interfaces/IPGGOracleStakeVoting.sol";
import "../../registries/GaltGlobalRegistry.sol";


interface IPGGConfig {
  function n() external view returns(uint256);
  function m() external view returns(uint256);
  function ggr() external view returns(GaltGlobalRegistry);
  function globalProposalSupport(uint256) external view returns(bool);
  function setThreshold(bytes32 _key, uint256 _value) external;
  function setMofN(uint256 _m, uint256 _n) external;
  function setMinimalArbitratorStake(uint256 _value) external;
  function setApplicationConfigValue(bytes32 _key, bytes32 _value) external;
  function addExternalRole(address _address, bytes32 _role) external;
  function removeExternalRole(address _address, bytes32 _role) external;
  function addInternalRole(address _address, bytes32 _role) external;
  function removeInternalRole(address _address, bytes32 _role) external;
  function setGlobalProposalSupport(uint256 _globalProposalId, bool _isSupported) external;
  function setContractAddress(bytes32 _key, address _address) external;
  function applicationConfig(bytes32) external view returns (bytes32);
  function minimalArbitratorStake() external view returns(uint256);
  function defaultProposalThreshold() external view returns(uint256);
  function thresholds(bytes32) external view returns(uint256);
  function getMultiSig() external view returns (IPGGMultiSig);
  function getArbitratorStakes() external view returns (IPGGArbitratorStakeAccounting);
  function getOracleStakes() external view returns (IPGGOracleStakeAccounting);
  function getOracles() external view returns (IPGGOracles);
  function getMultiSigCandidateTop() external view returns (IPGGMultiSigCandidateTop);
  function getDelegateSpaceVoting() external view returns (IPGGDelegateReputationVoting);
  function getDelegateGaltVoting() external view returns (IPGGDelegateReputationVoting);
  function getOracleStakeVoting() external view returns (IPGGOracleStakeVoting);
  function getExternalRoles(bytes32 _role) external view returns(address[] memory);
  function hasExternalRole(bytes32 _role, address _address) external view returns(bool);
  function getInternalRoles(bytes32 _role) external view returns(address[] memory);
  function hasInternalRole(bytes32 _role, address _address) external view returns(bool);
  function getThresholdMarker(address _destination, bytes calldata _data) external pure returns(bytes32 marker);
}
