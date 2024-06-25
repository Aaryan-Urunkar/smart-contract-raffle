// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test{

    HelperConfig helperConfig;

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

    function setUp() external{
        
    }

    function test_WorksForSepolia() external {
        vm.chainId(11155111);
        helperConfig = new HelperConfig();
        (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey //Its actually an hex value but solidity converts it
        ) = helperConfig.activeConfig();
        assertEq(vrfCoordinator , address(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B));
        assertEq(link , 0x779877A7B0D9E8603169DdbD7836e478b4624789);
        assertEq(deployerKey , vm.envUint("PRIVATE_KEY"));
    }

    function test_WorksForAnvil() external {
        vm.chainId(31337);
        helperConfig = new HelperConfig();
        (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey //Its actually an hex value but solidity converts it
        ) = helperConfig.activeConfig();

        assertEq(deployerKey ,helperConfig.DEFAULT_ANVIL_PRIVATE_KEY());
        assertEq(vrfCoordinator, address(helperConfig.mock()));
        assertEq(link , address(helperConfig.mockLinkToken()));
    }
}