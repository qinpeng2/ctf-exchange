// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2} from "forge-std/Script.sol";
import { CTFExchange } from "exchange/CTFExchange.sol";
import {IConditionalTokens} from "exchange/interfaces/IConditionalTokens.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @title ExchangeDeployment
/// @notice Script to deploy the CTF Exchange
/// @author Polymarket
contract CTFScript is Script {

    function setUp() public {}
    
    function run() public {

        vm.startBroadcast();

        IConditionalTokens ctf = IConditionalTokens(vm.envAddress("CTF"));

        // #####################
        // prepare(ctf);
        // ct.prepareCondition(oracle, questionId, outcomeSlotCount);
        console2.log("CTF Address:", address(ctf));

        // #####################
        // call the getCondtionId function and console the result to log
        console2.log("Condition ID:", ctf.getOutcomeSlotCount(getConditionId(ctf)));

        redeem(ctf);

        vm.stopBroadcast();
    }

    function prepare(IConditionalTokens ctf) public {
        // oracle, questionId, outcomeSlotCount
        ctf.prepareCondition(vm.envAddress("ORACLE"), 0x0000000000000000000000000000000000000000000000000000000000000001, 3);
        // https://sepolia.basescan.org/tx/0x504d249161cd639bb7fac73f3fda8dda9565b3eafc8367dc0387f632bff42d90
    }

    function getConditionId(IConditionalTokens ctf) public returns(bytes32){
        return ctf.getConditionId(vm.envAddress("ORACLE"), 0x0000000000000000000000000000000000000000000000000000000000000001, 3);
        // 0xcdd12cafd4d5970ef086b23728537815a2976d4c19a341525008c56512a9ff03
    }

    function getCollectionId(IConditionalTokens ctf) public {
        // index set
        // A, B, C
        // 0, 1, 1 | B or C: 0b110 = 6
        // 1, 0, 0 | A: 0b001 = 1
        // another case
        // 0, 1, 0 | B: 0b010 = 2
        // 0, 0, 1 | C: 0b100 = 4
        bytes32 parentCollectionIdC = ctf.getCollectionId(0x0000000000000000000000000000000000000000000000000000000000000000, getConditionId(ctf), 6);
        // 0x140ed16e7844444f28399ca11a551738146a2721f1702e6a34f30b13bb7ae077

        // Hi, Low
        // 1, 0 | Hi: 0b01 = 1
        // 0, 1 | Low: 0b10 = 2
        ctf.getCollectionId(parentCollectionIdC, getConditionId(ctf), 1);
    }

    function getPosition(IConditionalTokens ctf) public returns (uint256) {
        return ctf.getPositionId(IERC20(vm.envAddress("COLLATERAL")), ctf.getCollectionId(0x0000000000000000000000000000000000000000000000000000000000000000, getConditionId(ctf), 6));
    }

    function split(IConditionalTokens ctf) public {

        uint256[] memory partition = new uint256[](2);
        partition[0] = uint256(1);
        partition[1] = uint256(6);

        IERC20 collateralToken = IERC20(vm.envAddress("COLLATERAL"));
        collateralToken.approve(address(ctf), 1000000000);
        
        ctf.splitPosition(collateralToken,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        getConditionId(ctf),
        partition,
        1000
        );
        // https://sepolia.basescan.org/tx/0xc94dae0731e42a7795dda60e72c441fd41fd14963a388b847acceead59983134
    }

    function merge(IConditionalTokens ctf) public {

        uint256[] memory partition = new uint256[](2);
        partition[0] = uint256(1);
        partition[1] = uint256(6);

        IERC20 collateralToken = IERC20(vm.envAddress("COLLATERAL"));
        ctf.mergePositions(collateralToken,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        getConditionId(ctf),
        partition,
        80
        );
        // https://sepolia.basescan.org/tx/0x0581e5dd3155b3f7a1502ec902d0621771a6e782dbb7e099cd82a85cc9b7f910
    }

    function report(IConditionalTokens ctf) public {
        uint256[] memory payouts = new uint256[](3);
        payouts[0] = uint256(0);
        payouts[1] = uint256(1);
        payouts[0] = uint256(0);
        ctf.reportPayouts(0x0000000000000000000000000000000000000000000000000000000000000001, payouts);
    }

    function redeem(IConditionalTokens ctf) public {
        uint256[] memory partition = new uint256[](2);
        partition[0] = uint256(1);
        partition[1] = uint256(6);
        ctf.redeemPositions(IERC20(vm.envAddress("COLLATERAL")), 0x0000000000000000000000000000000000000000000000000000000000000000, getConditionId(ctf), partition);
    }

}
