//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundeMeTest is Test {
    FundMe fundMe; //FundMe is type of contract
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    address USER = makeAddr("user");

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); //fundMe is variable of type FundMe
        DeployFundMe deployeFundMe = new DeployFundMe();
        fundMe = deployeFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        console.log("Current version:", version);

        assertEq(version, 4, "Unexpected version");
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line should revert!
        //assert tx fails/reevert
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the nxt tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        uint256 gasStart = gasleft(); // 1000
        vm.txGasPrice(GAS_PRICE); // -------> cheat code
        vm.prank(fundMe.getOwner()); //  C: 200
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); // 8000
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //ASSERT
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundmed
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundmed
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
