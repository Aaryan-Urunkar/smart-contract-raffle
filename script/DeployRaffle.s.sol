// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "forge-std/Script.sol";
import "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription , FundSubscription , AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script{
    function run() external returns (Raffle , HelperConfig){
        
        HelperConfig helperConfig = new HelperConfig();
        (uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyhash,
        uint subscriptionId,
        uint32 callbackGasLimit , address link, uint256 deployerKey) = helperConfig.activeConfig();

        

        if(subscriptionId == 0){
            //Create a new subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator , deployerKey);

            //Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator , subscriptionId , link , deployerKey);
            console.log("Funding happened...");
        }

        
        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee, interval, vrfCoordinator, keyhash, subscriptionId ,callbackGasLimit);
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle) , vrfCoordinator , subscriptionId , deployerKey);
        return (raffle , helperConfig);
    }
}