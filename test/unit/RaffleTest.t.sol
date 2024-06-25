// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import {Test , console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address payable indexed winner);

    Raffle raffle;
    HelperConfig helperConfig;

    address public player = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyhash;
    uint subscriptionId;
    uint32 callbackGasLimit;

    modifier RaffleEnteredAndTimePassed {
        vm.prank(player);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number +1);
        _;
    }

    modifier skipFork{
        if(block.chainid != 31337){
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.run();
        (entranceFee, interval, vrfCoordinator, keyhash, subscriptionId, callbackGasLimit ,,) = helperConfig.activeConfig();
        vm.deal(player , STARTING_USER_BALANCE);
    }

    function test_RaffleIsOpenWhenInitialized()external view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////////////
    //enterRaffle //////////
    ///////////////////////

    function test_revertingOnInsufficientFee() external {
        vm.prank(player);
        vm.expectRevert();
        raffle.enterRaffle();
    }

    function test_RecordNewPlayers() external {
        vm.prank(player);
        raffle.enterRaffle{value:entranceFee }();
        address recordedPlayer = raffle.getPlayer(0);
        assertEq(recordedPlayer , player);
    }

    function test_EnteringWhenRaffleIsCalculatingWinner() external RaffleEnteredAndTimePassed {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value:entranceFee}();
    }

    function test_EmitsEnteredRaffle() external {
        vm.prank(player);
        //Use the expectEmit cheatcode
        vm.expectEmit(/*first 3 parameters are topics*/true , false ,false , /*data */ false, address(raffle));

        emit EnteredRaffle(player);        
        
        raffle.enterRaffle{value: entranceFee}();
    }

    /////////////////////////
    //checkUpkeep //////////
    ///////////////////////

    function test_IfContractHasNoBalanceFunctionReturnsFalse() external {
        vm.warp(block.timestamp + interval +1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded ,) = raffle.checkUpkeep('');
        assertEq(upkeepNeeded , false);
    }

    function test_IfContractIsCalculatingFunctionReturnsFalse()external RaffleEnteredAndTimePassed {
        raffle.performUpkeep("");

        (bool upkeepNeeded ,) = raffle.checkUpkeep('');
        assertEq(upkeepNeeded , false);
    }

    function test_FunctionReturnsFalseIfEnoughTimeHasntPassed() external {
        vm.prank(player);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded , ) = raffle.checkUpkeep('');
        assert(upkeepNeeded == false);
    }

    ///////////////////////////
    //performUpkeep //////////
    /////////////////////////

    function test_performUpkeepCannotRunIfCheckUpkeepIsFalse() external {
        vm.prank(player);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector,address(raffle).balance, raffle.getNoOfPlayers(), 0));
        raffle.performUpkeep("");
    }

    function test_performUpkeepUpdatesRaffleState() external RaffleEnteredAndTimePassed {
        raffle.performUpkeep('');
        assert(Raffle.RaffleState.CALCULATING == raffle.getRaffleState());
    }

    function test_performUpkeepEmitsRequestId() external RaffleEnteredAndTimePassed {
        vm.recordLogs();
        raffle.performUpkeep('');
        Vm.Log[] memory events = vm.getRecordedLogs();
        bytes32 requestId = events[1].topics[1]; //Ideally since requestId is the only topic it should be at index 0 but it is actually at index since the first topic is the whole event itself
        assert(uint256(requestId) > 0);
    }

    ////////////////////////////////
    //fulfillRandomWords //////////
    //////////////////////////////

    function test_FulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) external skipFork {
        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
    }

    function test_FulfillRandomWordsPicksAWinnerAndSendsMoney() external RaffleEnteredAndTimePassed skipFork{

        uint256 noOfPeople = 5;
        uint256 startingIndex = 0;
        for(uint256 i=startingIndex; i< noOfPeople;i++){
            address player = address(uint160(i));
            hoax(player , STARTING_USER_BALANCE);
            raffle.enterRaffle{value:entranceFee}();
        }

        uint256 prize = (entranceFee *(raffle.getNoOfPlayers())) ;

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number +1);

        // //Checking for event emit
        // vm.expectEmit(true, false,false,false,address(raffle));
        // emit WinnerPicked(payable(raffle.getRecentWinner()));

        vm.recordLogs();
        raffle.performUpkeep('');
        Vm.Log[] memory events = vm.getRecordedLogs();
        bytes32 requestId = events[1].topics[1];


        

        // console.log(address(raffle).balance);
        // console.log(prize - entranceFee);

        //Pretend to be chainlink and get random number & pick winner
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId) , address(raffle));
        

        //Asserts
        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
        assert(raffle.getNoOfPlayers() == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE - entranceFee + prize);

    }
}