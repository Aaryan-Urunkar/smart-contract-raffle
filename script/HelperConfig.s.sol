// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
//import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script{

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyhash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey; //Its actually an hex value but solidity converts it
    }

    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    NetworkConfig public activeConfig;
    VRFCoordinatorV2_5Mock public mock;
    LinkToken public mockLinkToken;

    constructor(){
        if(block.chainid == 31337){
            activeConfig  = getAnvilETHConfig();
        } else if(block.chainid == 11155111) {
            activeConfig = getSepoliaETHConfig();
        }
    }

    function getSepoliaETHConfig() internal view returns (NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval : 60,
            vrfCoordinator :0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B ,
            keyhash : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId : 15322696313419978122325979300450214981658587637276318894280229456994103217532, //Update this with yur sub id
            callbackGasLimit : 500000 ,
            link : 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey : vm.envUint("PRIVATE_KEY")
        });
    }

    function getAnvilETHConfig() internal returns (NetworkConfig memory){

        uint96 baseFee = 0.25 ether;
        uint96 gasPrice = 1e9; 
        int256 weiPerUnitLink = 3889810000000000; //Current LINK/ETH price 
        
        vm.startBroadcast();
        mock = new VRFCoordinatorV2_5Mock(baseFee , gasPrice , weiPerUnitLink);

        mockLinkToken = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval : 60,
            vrfCoordinator :address(mock) ,
            keyhash : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId : 0, //Update this with yur sub id
            callbackGasLimit : 500000 ,
            link: address(mockLinkToken),
            deployerKey : DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}