// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test , console} from "forge-std/Test.sol";
import {AddConsumer , FundSubscription , CreateSubscription} from "../../script/Interactions.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import "../../script/DeployRaffle.s.sol";

contract InteractionsTest is Test {
    event NewConsumer(address indexed raffle, uint256 subscriptionId);
    event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);

    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyhash;
    uint subscriptionId;
    uint32 callbackGasLimit;
    uint256 deploymentKey;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinator, keyhash, subscriptionId, callbackGasLimit ,,deploymentKey) = helperConfig.activeConfig();
    }

    function test_EventEmittedWhenConsumerAdded() external {
        vm.expectEmit();
        //emit SubscriptionConsumerAdded(subscriptionId , address(raffle));
        emit NewConsumer(address(raffle) , subscriptionId);
        AddConsumer addConsumer =new AddConsumer();
        addConsumer.addConsumer(address(raffle),vrfCoordinator,subscriptionId, deploymentKey);
        //address recentRaffleDeployment = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        //vm.expectEmit(true, false,false,false , address(addConsumer));


        console.log(subscriptionId);
        console.log(address(raffle));
        //emit NewConsumer(address(raffle));
        //emit SubscriptionConsumerAdded(subscriptionId , address(raffle));

        //addConsumer.run();
    }
}
