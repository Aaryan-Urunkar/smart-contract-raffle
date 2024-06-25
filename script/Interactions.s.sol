// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script , console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script{
    function run() external returns (uint256 ){
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256 ){
        HelperConfig helperConfig=new HelperConfig();
        (,,address vrfCoordinator ,,,,,uint256 deployerKey) = helperConfig.activeConfig();
        return createSubscription(vrfCoordinator , deployerKey);
    }

    function createSubscription(address vrfCoordinator , uint256 deployerKey) public returns(uint256 ){
        console.log("Creating subscription on chain id: " , block.chainid);
        vm.startBroadcast(deployerKey);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub id is : " , subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }
    
}

contract FundSubscription is Script {
    uint256 constant public FUND_AMOUNT = 10 ether; 

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig=new HelperConfig();
        (,,address vrfCoordinator ,,uint subId,,address link,uint256 deployerKey) = helperConfig.activeConfig();

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            uint256 updatedSubId = createSub.run();
            subId = updatedSubId;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinator);
        }
        fundSubscription(vrfCoordinator , subId , link , deployerKey);
    }

    function fundSubscription(address vrfCoordinator ,uint subId,address link,uint256 deployerKey) public {
        console.log("Funding subscription : " , subId);
        console.log("Using VRF Coordinator : " , vrfCoordinator);
        console.log("On chain ID: " , block.chainid);
        if(block.chainid == 31337){ //localhost
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId , FUND_AMOUNT);
            
            vm.stopBroadcast();
        } else { // A testnet/mainnet
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT ,abi.encode(subId));
            vm.stopBroadcast();
        }

    }
}

contract AddConsumer is Script {

    event NewConsumer(address indexed raffle , uint256 subscriptionId);

    address recentRaffleDeployment;

    function run() external{
        //To add consumer contract, we need address of most recently deployed contract
        recentRaffleDeployment = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerUsingConfig(recentRaffleDeployment);
    }

    function addConsumerUsingConfig( address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator ,,uint256 subId,,,uint256 deployerKey) = helperConfig.activeConfig();
        addConsumer(raffle , vrfCoordinator, subId , deployerKey);
    }

    function addConsumer(address raffle , address vrfCoordinator , uint256 subId , uint256 deployerKey) public {
        console.log("Adding consumer contract : " , raffle);
        console.log("To VRF Coordinator : " , vrfCoordinator);
        console.log("At chain ID : " , block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer( subId , raffle );
        vm.stopBroadcast();

        console.log(subId);
        console.log(address(raffle));
        emit NewConsumer(raffle , subId);
    }
}