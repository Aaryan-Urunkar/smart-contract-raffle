//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
//import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/** 
 * @title A sample raffle contract
 * @author Aaryan 
 * @notice This contract is for creating a sample raffle
 * @dev Uses Chainlink VRF
*/

contract Raffle is VRFConsumerBaseV2Plus{
    /*errors*/
    error Raffle_NotEnoughETHSent();
    error Raffle_TransferFail();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 balance, uint256 noOfPlayers, uint256 raffleStatus);

    /* type declarations*/
    enum RaffleState {
        OPEN , CALCULATING
    }


    /* state variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address[] private s_players;
    address private s_recentWinner;
    VRFCoordinatorV2_5Mock immutable i_vrfCoordinator;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    RaffleState private s_raffleState ;
    
    uint32 constant NUM_WORDS=1;
    uint16 private constant REQUEST_CONFIRMATIONS=4;

    event EnteredRaffle(address indexed player);
    event WinnerPicked(address payable indexed winner);
    event RequestedRaffleWinner(uint256 indexed reuqestId);

    constructor(uint256 entranceFee , uint256 interval , address vrfCoordinator , bytes32 keyhash , uint256 subscriptionId , uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2_5Mock( vrfCoordinator );
        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState  = RaffleState.OPEN;
    }

    function enterRaffle() public payable{
        //require(msg.value > i_entranceFee , "Not enough ETH sent!");
        
        if(msg.value < i_entranceFee){
            revert Raffle_NotEnoughETHSent();
        }
        //require() not used because it is not gas efficient

        if(s_raffleState != RaffleState.OPEN){
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(msg.sender);

        //Emitting an event
        emit EnteredRaffle(msg.sender);
    }


    //1.Pick a random player
    //2.Get automatically called
    function performUpkeep(bytes calldata /*performData*/) external  { //Function chosen to pick winner

        (bool upkeepNeeded ,) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle_UpkeepNotNeeded(address(this).balance ,s_players.length , uint256(s_raffleState));
        }

        //To check if the function can be called
        if(block.timestamp - s_lastTimeStamp < i_interval){
            revert();
        }
        s_raffleState = RaffleState.CALCULATING; //Hence people wont be able to enter raffle while we are waiting for random number
        console.log(i_subscriptionId);
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyhash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: true
                    })
                )
            })
        );
        //So how this works is that we are going to make a request to the chainlink node to give us a random number
        //It's going to call a very specific contract on-chain called the IVRFCoordinator
        //That contract is going to call rawFulfillRandomWords which is going to call fulfillRandomWords()(the overriden one which we are creating)
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{
        uint256 indexOfWinner = randomWords[0] % s_players.length;

        address payable winner = payable (s_players[indexOfWinner]);
        //Storing address of winner and casting it into payable address type

        s_recentWinner = winner;

        (bool success ,) = winner.call{value:address(this).balance}("");
        if(!success){
            revert Raffle_TransferFail();
        }
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0); //Resetting an array
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(winner);
    }


    /**
     * @dev This is the function that Chainlink automation nodes call to see when it's time to perform an upkeep. 
     * The following should be true for this to return true:
     *  1] s_raffleState should be OPEN
     *  2] The required time interval has passed between two lotteries
     *  3] The contract is funded with LINK
     */
    function checkUpkeep(bytes memory checkData)public view returns(bool , bytes memory){
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance >0;
        bool upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers ;
        return (upkeepNeeded , "0x0");
    }

    //getters

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    } 
    
    function getLastTimestamp() external view returns(uint256){
        return s_lastTimeStamp;
    }

    function getPlayer(uint256 _playerindex) external view returns (address){
        return s_players[_playerindex];
    }

    function getNoOfPlayers() external view returns(uint256){
        return s_players.length;
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }
}