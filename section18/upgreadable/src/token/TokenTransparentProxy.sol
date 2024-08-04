// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TokenTransparentProxy is TransparentUpgradeableProxy {

    constructor(address _logic, address initialOwner, bytes memory _data) TransparentUpgradeableProxy(_logic, initialOwner, _data) {}
    

    function proxyAdmin() public returns (address) {
        return _proxyAdmin();
    }

}