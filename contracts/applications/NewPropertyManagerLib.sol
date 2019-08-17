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

pragma solidity 0.5.10;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "@galtproject/geodesic/contracts/interfaces/IGeodesic.sol";
import "./NewPropertyManager.sol";
import "./AbstractApplication.sol";
import "../interfaces/ISpaceToken.sol";
import "../registries/interfaces/ISpaceGeoDataRegistry.sol";


library NewPropertyManagerLib {
  using SafeMath for uint256;

  function rejectApplicationHelper(
    NewPropertyManager.Application storage _a,
    string calldata _message
  )
    external
  {
    require(
      _a.status == NewPropertyManager.ApplicationStatus.PENDING,
      "Application status should be PENDING");

    uint256 len = _a.assignedOracleTypes.length;

    for (uint256 i = 0; i < len; i++) {
      bytes32 currentOracleType = _a.assignedOracleTypes[i];
      if (_a.validationStatus[currentOracleType] == NewPropertyManager.ValidationStatus.PENDING) {
        revert("One of the oracle type has PENDING status");
      }
    }

    bytes32 senderOracleType = _a.addressOracleTypes[msg.sender];
    _a.oracleTypeMessages[senderOracleType] = _message;
  }

  function mintToken(
    GaltGlobalRegistry _ggr,
    NewPropertyManager.Application storage _a,
    address _to
  ) external {
    ISpaceGeoDataRegistry spaceGeoData = ISpaceGeoDataRegistry(_ggr.getSpaceGeoDataRegistryAddress());

    uint256 spaceTokenId = ISpaceToken(_ggr.getSpaceTokenAddress()).mint(_to);

    _a.spaceTokenId = spaceTokenId;
    NewPropertyManager.Details storage d = _a.details;

    spaceGeoData.setSpaceTokenType(spaceTokenId, d.tokenType);
    spaceGeoData.setSpaceTokenContour(spaceTokenId, d.contour);
    spaceGeoData.setSpaceTokenHighestPoint(spaceTokenId, d.highestPoint);
    spaceGeoData.setSpaceTokenHumanAddress(spaceTokenId, d.humanAddress);
    spaceGeoData.setSpaceTokenArea(spaceTokenId, d.area, d.areaSource);
    spaceGeoData.setSpaceTokenLedgerIdentifier(spaceTokenId, d.ledgerIdentifier);
    spaceGeoData.setSpaceTokenDataLink(spaceTokenId, d.dataLink);
  }
}
