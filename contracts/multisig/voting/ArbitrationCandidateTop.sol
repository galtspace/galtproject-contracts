/*
 * Copyright ©️ 2018 Galt•Space Society Construction and Terraforming Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka),
 * [Dima Starodubcev](https://github.com/xhipster),
 * [Valery Litvin](https://github.com/litvintech) by
 * [Basic Agreement](http://cyb.ai/QmSAWEG5u5aSsUyMNYuX2A2Eaz4kEuoYWUkVBRdmu9qmct:ipfs)).
 *
 * Copyright ©️ 2018 Galt•Core Blockchain Company
 * (Founded by [Nikolai Popeka](https://github.com/npopeka) and
 * Galt•Space Society Construction and Terraforming Company by
 * [Basic Agreement](http://cyb.ai/QmaCiXUmSrP16Gz8Jdzq6AJESY1EAANmmwha15uR3c1bsS:ipfs)).
 */

pragma solidity 0.5.3;

import "@galtproject/libs/contracts/traits/Permissionable.sol";
import "@galtproject/libs/contracts/collections/ArraySet.sol";
import "../ArbitratorsMultiSig.sol";
import "../OracleStakesAccounting.sol";
import "../ArbitrationConfig.sol";
import "../ArbitratorStakeAccounting.sol";
import "../../collections/AddressLinkedList.sol";
import "../../collections/VotingLinkedList.sol";
import "./interfaces/IArbitrationCandidateTop.sol";

contract ArbitrationCandidateTop is IArbitrationCandidateTop, Permissionable {
  using ArraySet for ArraySet.AddressSet;
  using AddressLinkedList for AddressLinkedList.Data;

  event ReputationMint(address delegate, uint256 amount);
  event ReputationBurn(address delegate, uint256 amount);
  event ReputationChanged(address _delegate, uint256 prevReputation, uint256 newReputation);

  uint256 public constant SPACE_REPUTATION_SHARE = 40;
  uint256 public constant GALT_REPUTATION_SHARE = 30;
  uint256 public constant STAKE_REPUTATION_SHARE = 30;

  event Recalculate(
    address candidate,
    bool isIgnored,
    uint256 candidateWeightBefore,
    uint256 candidateWeightAfter
  );

  event RecalculateSharesAndRatios(
    address candidate,
    uint256 candidateSpaceReputationShare,
    uint256 candidateGaltReputationShare,
    uint256 candidateStakeReputationShare,
    uint256 spaceReputationRatio,
    uint256 galtReputationRatio,
    uint256 stakeReputationRatio
  );

  event ReputationBurnWithRevoke(
    address delegate,
    uint256 remainder,
    uint256 limit
  );

  // limit for SpaceReputation delegation
  uint256 private constant DELEGATE_CANDIDATES_LIMIT = 5;
  uint256 private constant DECIMALS = 10**6;

  // Candidate => isIgnored
  mapping(address => bool) private ignoredCandidates;

  uint256 public totalWeight;

  VotingLinkedList.Data votingData;
  AddressLinkedList.Data votingList;

  ArbitrationConfig arbitrationConfig;

  constructor(
    ArbitrationConfig _arbitrationConfig
  )
    public
  {
    arbitrationConfig = _arbitrationConfig;
    votingList.withTail = true;
    // FIX: should rely on arbitrationConfig
    votingData.maxCount = _arbitrationConfig.n();
  }

  function recalculate(address _candidate) external {
    uint256 candidateWeightAfter = 0;
    uint256 candidateWeightBefore = getCandidateWeight(_candidate);
    bool ignore = (ignoredCandidates[_candidate] == true);

    if (!ignore) {
      candidateWeightAfter = _calculateWeight(_candidate);
    }

    emit Recalculate(
      _candidate,
      ignore,
      candidateWeightBefore,
      candidateWeightAfter
    );

    if (candidateWeightBefore > candidateWeightAfter) {
      totalWeight -= (candidateWeightBefore - candidateWeightAfter);
    } else {
      totalWeight += (candidateWeightAfter - candidateWeightBefore);
    }

    VotingLinkedList.insertOrUpdate(votingList, votingData, _candidate, candidateWeightAfter);
  }

  function _calculateWeight(address _candidate) internal returns (uint256) {
    uint256 candidateSpaceReputationShare = arbitrationConfig.getDelegateSpaceVoting().shareOf(_candidate, DECIMALS);
    uint256 candidateGaltReputationShare = arbitrationConfig.getDelegateGaltVoting().shareOf(_candidate, DECIMALS);
    uint256 candidateStakeReputationShare = arbitrationConfig.getOracleStakeVoting().shareOf(_candidate, DECIMALS);

    uint256 spaceReputationRatio = 0;
    uint256 galtReputationRatio = 0;
    uint256 stakeReputationRatio = 0;

    if (candidateSpaceReputationShare > 0) {
      spaceReputationRatio = (candidateSpaceReputationShare * SPACE_REPUTATION_SHARE) / 100;
    }

    if (candidateGaltReputationShare > 0) {
      galtReputationRatio = (candidateGaltReputationShare * GALT_REPUTATION_SHARE) / 100;
    }

    if (candidateStakeReputationShare > 0) {
      stakeReputationRatio = (candidateStakeReputationShare * STAKE_REPUTATION_SHARE) / 100;
    }

    emit RecalculateSharesAndRatios(
      _candidate,
      candidateSpaceReputationShare,
      candidateGaltReputationShare,
      candidateStakeReputationShare,
      spaceReputationRatio,
      galtReputationRatio,
      stakeReputationRatio
    );

    return (spaceReputationRatio + galtReputationRatio + stakeReputationRatio);
  }

  function pushArbitrators() external {
    arbitrationConfig
      .getMultiSig()
      .setArbitrators(getCandidatesWithStakes());
  }

  function ignoreMe(bool _value) external {
    ignoredCandidates[msg.sender] = _value;
  }

  // Getters

  function getCandidateWeight(address _candidate) public view returns (uint256) {
    uint256 candidateSpaceReputationShare = arbitrationConfig.getDelegateSpaceVoting().shareOf(_candidate, DECIMALS);
    uint256 candidateGaltReputationShare = arbitrationConfig.getDelegateGaltVoting().shareOf(_candidate, DECIMALS);
    uint256 candidateStakeReputationShare = arbitrationConfig.getOracleStakeVoting().shareOf(_candidate, DECIMALS);

    uint256 spaceReputationRatio = 0;
    uint256 galtReputationRatio = 0;
    uint256 stakeReputationRatio = 0;

    if (candidateSpaceReputationShare > 0) {
      spaceReputationRatio = (candidateSpaceReputationShare * SPACE_REPUTATION_SHARE) / 100;
    }

    if (candidateGaltReputationShare > 0) {
      galtReputationRatio = (candidateGaltReputationShare * GALT_REPUTATION_SHARE) / 100;
    }

    if (candidateStakeReputationShare > 0) {
      stakeReputationRatio = (candidateStakeReputationShare * STAKE_REPUTATION_SHARE) / 100;
    }

    return (spaceReputationRatio + galtReputationRatio + stakeReputationRatio);
  }

  function getCandidatesWithStakes() public view returns (address[] memory) {
    if (votingList.count == 0) {
      return new address[](0);
    }

    IArbitratorStakeAccounting arbitratorStakes = arbitrationConfig.getArbitratorStakes();
    address[] memory p = new address[](votingList.count);
    uint256 minimalStake = arbitrationConfig.minimalArbitratorStake();
    uint256 pI = 0;

    address currentAddress = votingList.head;

    for (uint256 i = 0; i < p.length; i++) {
      if (arbitratorStakes.balanceOf(currentAddress) >= minimalStake) {
        p[pI] = currentAddress;
        pI += 1;
      }

      currentAddress = votingList.nodes[currentAddress].next;
    }

    if (pI == 0) {
      return new address[](0);
    }

    // p.length = pI
    assembly { mstore(p, pI) }

    return p;
  }

  function getCandidates() public view returns (address[] memory) {
    if (votingList.count == 0) {
      return new address[](0);
    }

    address[] memory c = new address[](votingList.count);

    address currentAddress = votingList.head;

    for (uint256 i = 0; i < c.length; i++) {
      c[i] = currentAddress;

      currentAddress = votingList.nodes[currentAddress].next;
    }

    return c;
  }

  function getCandidateWeights(
    address[] calldata _candidates
  )
    external
    view
    returns (uint256)
  {
    uint256 total = 0;

    for (uint256 i = 0; i < _candidates.length; i++) {
      total += getCandidateWeight(_candidates[i]);
    }

    return total * 100 / DECIMALS;
  }

  function getTopCandidateWeight(address _candidate) public view returns (uint256) {
    return votingData.votes[_candidate];
  }

  function isCandidateInList(address _candidate) external view returns (bool) {
    return VotingLinkedList.isExists(votingList, _candidate);
  }

  function isIgnored(address _candidate) external view returns (bool) {
    return ignoredCandidates[_candidate];
  }

  function getSize() external view returns (uint256 size) {
    return votingList.count;
  }
}