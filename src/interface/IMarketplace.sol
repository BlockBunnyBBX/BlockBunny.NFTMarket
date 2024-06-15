// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IMarketplace {

    //list of errors
    error Marketplace__InsufficientBalance();
    error Marketplace__NotOwner();
    error Marketplace__TokenNotForSale();
    error Marketplace__TokenAlreadyForSale();   //add check for this
    error Marketplace__TransferFailed();//add check for this
    error Marketplace__InvalidPrice();
    error Marketplace__IncorrectPrice();  
    error Marketplace__IncorrectListingPrice();
    error Marketplace__IncorrectSupply();
    error Marketplace__MaxSupply();
    error Marketplace__NotApproved();
    error Marketplace__IncorrectSaleInfo();
    error Marketplace__ItemListedByYou();
    error Marketplace__InsufficientPrice();
    //List of structs
    struct Listing {
        uint256 price;
        address seller;
    }

    struct SaleInfo {
        address seller;
        uint256 price;
    }
    
    struct CollectionInfo {
        address creatorAddress;
    }

    //events
     event CreateCollection(
        address indexed collectionAddress,
        string name,
        string symbol,
        uint256 maxSupply,
        address indexed creator
    );

    event CreateItems(
        address indexed _collection,
        uint256 indexed _tokenID,
        string _tokenURI,
        uint256 _price,
        address _creator
    );
    event NewItemListed(
        address indexed _collection,
        uint256 indexed _tokenID,
        uint256 _price,
        address _seller
    );

    event BuyItem(
        address indexed _collection,
        uint256 indexed _tokenID,
        uint256 _price,
        address _seller,
        address _buyer
    );


    //functions
    function createCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply
    ) external payable returns (address);

    function CreateItemss(
        address collection,
        string memory tokenURI,
        uint32 supply,
        uint256 price
    ) external;

    function listItemForSale(
        address collection,
        uint256 tokenID,
        uint256 price
    ) external payable;

    function buyForListedItem(
        address collection,
        uint256 tokenID
    ) external payable;
}