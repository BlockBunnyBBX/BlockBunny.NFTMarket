// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Marketplace} from "../src/Marketplace.sol";
import {NFTCollection} from "../src/NFTCollection.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {console} from "forge-std/console.sol";

contract MarketplaceTest is Test {
    uint256 public constant COLLECTION_FEE = 0.0001 ether;
    uint256 public constant INCORRECT_FEE = 0.01 ether;
    Marketplace public marketplace;
    NFTCollection public nftCollection;
    MockERC20 public token;

    address public OWNER = address(1);
    address public USER = address(2);

    function setUp() public {
        OWNER = msg.sender;
        token = new MockERC20();
        marketplace = new Marketplace(address(token));
        vm.deal(USER, 10 ether);
        vm.deal(OWNER, 10 ether);
    }

    function test_CreateCollection() public returns(address) {
        vm.prank(USER);
        address collection = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        return collection;        
    }

    function test_Revert_CollectionWithIncorrectFee() public {
        vm.prank(USER);
        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectPrice()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        marketplace.createCollection{value: INCORRECT_FEE}("Test Collection", "TCOL", 10);      
    }

    function test_Revert_CollectionWithIncorrectSupply() public {
        vm.prank(USER);
        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectSupply()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 0);      
    }

    function test_createItems() public {
        vm.prank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10); 
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether); 
    }

    function test_CreatemultipleItems() public {
        vm.prank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        marketplace.CreateItemss(collectionAddress, "www.test.com", 5, 0.0001 ether);
    }

    function test_Revert_createItemWithZeroPrice() public {
        vm.prank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);

        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectPrice()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0 ether);
    }

    function test_Revert_createItemWithZeroSupply() public {
        vm.prank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);

        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectSupply()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.CreateItemss(collectionAddress, "www.test.com", 0, 0.0001 ether);
    }

    function test_Revert_createItemWithMaxSupply() public {
        vm.prank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);

        bytes4 selector = bytes4(keccak256("NFTCollection__MaxSupplyReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.CreateItemss(collectionAddress, "www.test.com", 11, 0.0001 ether);
    }
    
    function test_listItemForSale() public {       
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
        nftCollection.setApprovalForAll(address(marketplace), true);
        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 0.0001 ether);
    }

    function test_RevertListItemWithIncorrectFee() public {
        vm.startPrank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);  
        
        nftCollection.setApprovalForAll(address(marketplace), true);
        

        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectListingPrice()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.listItemForSale{value: INCORRECT_FEE}(collectionAddress, 1, 0.0001 ether);

        vm.stopPrank();
    }

    function test_RevertListItemIfPriceZero() public {
        vm.startPrank(USER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
        nftCollection.setApprovalForAll(address(marketplace), true);
        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectPrice()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 0 ether);
        vm.stopPrank();
    }

    function test_RevertListItemIFNotOwner() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
        nftCollection.setApprovalForAll(address(marketplace), true);
        
        changePrank(USER);

        bytes4 selector = bytes4(keccak256("Marketplace__NotOwner()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 0.002 ether);
        vm.stopPrank();
    }

    function test_RevertListingNotApproved() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);  

        bytes4 selector = bytes4(keccak256("Marketplace__NotApproved()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 1 ether);

        vm.stopPrank();
    }

    function test_buyForListedItem() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
    
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
        
        nftCollection.setApprovalForAll(address(marketplace), true);
       
        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 1 ether);

        changePrank(USER);

        marketplace.buyForListedItem{value: COLLECTION_FEE}(collectionAddress, 1); 
    }

    function test_RevertBuyWithIncorrectFee() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
    
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
          
        nftCollection.setApprovalForAll(address(marketplace), true);

        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 1 ether);

        changePrank(USER);

        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectPrice()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.buyForListedItem{value: INCORRECT_FEE}(collectionAddress, 1); 
        
    }

    function test_RevertBuyIfNotListed() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
        
        bytes4 selector = bytes4(keccak256("Marketplace__IncorrectSaleInfo()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.buyForListedItem{value: COLLECTION_FEE}(collectionAddress, 1);       
    }

    function test_RevertBuyerCantBeSender() public {
        vm.startPrank(OWNER);
        address collectionAddress = marketplace.createCollection{value: COLLECTION_FEE}("Test Collection", "TCOL", 10);
        nftCollection = NFTCollection(collectionAddress);
    
        marketplace.CreateItemss(collectionAddress, "www.test.com", 1, 0.0001 ether);
      

        nftCollection.setApprovalForAll(address(marketplace), true);
    

        marketplace.listItemForSale{value: COLLECTION_FEE}(collectionAddress, 1, 1 ether);

        bytes4 selector = bytes4(keccak256("Marketplace__ItemListedByYou()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        marketplace.buyForListedItem{value: COLLECTION_FEE}(collectionAddress, 1);        
    }
}
