// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IMarketplace} from "./interface/IMarketplace.sol";
import {NFTCollection} from "./NftCollection.sol";

interface INFTCollection {
    function MintNFT(
        string calldata _tokenURI,
        address _to
    ) external returns (uint256);
}

/// @title Marketplace
/// @notice This contract is a marketplace for buying and selling NFTs
contract Marketplace is ReentrancyGuard, Ownable,  IMarketplace{

    IERC20 public immutable token;
    address[] public _allCollections;

    uint256 public constant createCollectionFee = 0.0001 ether;
    uint256 public constant LISTING_PRICE = 0.0001 ether;

    /**
     * @dev Create a new Marketplace instance.
     * @param tokenAddress The address of the token contract.
     */
    constructor(address tokenAddress)Ownable(msg.sender) {
        token = IERC20(tokenAddress);
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => SaleInfo)) public _nftInfoForSale;
    mapping(address => CollectionInfo) public _addedCollections;

    /// @notice Creates a new collection of NFTs
    /// @param name The name of the collection
    /// @param symbol The symbol of the collection
    /// @param maxSupply The maximum supply of the collection
    /// @return The address of the newly created collection
    function createCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply
    ) external payable override returns (address) {
        if (msg.value != LISTING_PRICE) {
            revert Marketplace__IncorrectPrice();
        }
        if (maxSupply <= 0) {
            revert Marketplace__IncorrectSupply();
        }
        NFTCollection collection = new NFTCollection(name, symbol, maxSupply);
        _addedCollections[address(collection)] = CollectionInfo({
            creatorAddress: msg.sender
        });
        _allCollections.push(address(collection));

        emit CreateCollection(
            address(collection),
            name,
            symbol,
            maxSupply,
            msg.sender
        );

        return address(collection);
    
    }

    /// @notice Creates multiple NFTs for a specific collection
    /// @param collection The address of the NFT collection in which NFT will be create
    /// @param tokenURI The URI of the NFT token
    /// @param supply The number of NFTs to create
    /// @param price The price of each NFT
    function CreateItemss(
        address collection,
        string memory tokenURI,
        uint32 supply,
        uint256 price
    ) external {
        if (price == 0) {revert Marketplace__IncorrectPrice();}
        if (!(supply > 0)) {
            revert Marketplace__IncorrectSupply();
        }

        for (uint32 i = 0; i < supply; i++) {
            uint256 tokenID = INFTCollection(collection).MintNFT(
                tokenURI,
                //address(this)
                msg.sender
            );
            _nftInfoForSale[collection][tokenID] = SaleInfo({
                seller: msg.sender,
                price: price
            });   
        
            emit CreateItems(
                address(collection),
                tokenID,
                tokenURI,
                price,
                msg.sender
            );
        }
    }

    /// @notice Lists an NFT for sale
    /// @param collection The address of the NFT collection in which NFT will be listed
    /// @param tokenId The ID of the NFT to be listed
    /// @param price The price of the NFT
    function listItemForSale(
        address collection, 
        uint256 tokenId, 
        uint256 price
    ) external payable override {
        if(msg.value != LISTING_PRICE){ revert Marketplace__IncorrectListingPrice();}
        isOwner(tokenOwner(collection, tokenId));
        if (price == 0) revert Marketplace__IncorrectPrice();
        
        if (
            !(IERC721(collection).isApprovedForAll(msg.sender, address(this)))
        ) {
            revert Marketplace__NotApproved();
        }
        _nftInfoForSale[collection][tokenId] = SaleInfo({
            seller: msg.sender,
            price: price
        });
        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);
        emit NewItemListed(collection, tokenId, price, msg.sender);
    }

    /// @notice Buys an NFT listed for sale
    /// @param collection The address of the NFT collection in which NFT will be bought
    /// @param tokenID The ID of the NFT to be bought
    function buyForListedItem(
        address collection,
        uint256 tokenID
    ) external payable override nonReentrant {

        SaleInfo memory saleInfo = _nftInfoForSale[collection][tokenID];
        if (!(saleInfo.seller != address(0x0) || saleInfo.price != 0)) {
            revert Marketplace__IncorrectSaleInfo();
        }
        if (!(saleInfo.seller != msg.sender)) {
            revert Marketplace__ItemListedByYou();
        }
        
        if (!(saleInfo.price == msg.value)) {
            revert Marketplace__IncorrectPrice();
        }
        if (_nftInfoForSale[collection][tokenID].seller == address(0)) revert Marketplace__TokenNotForSale();

        IERC721(collection).transferFrom(address(this), msg.sender, tokenID);
        _nftInfoForSale[collection][tokenID] = SaleInfo({
            seller: address(0),
            price: 0
        });

        emit BuyItem(
            collection,
            tokenID,
            saleInfo.price,
            saleInfo.seller,
            msg.sender
        );
    }

    //Helper Functions
    function getNFTInfoForSale(address collection, uint256 tokenId) external view returns(SaleInfo memory) {
        return _nftInfoForSale[collection][tokenId];
    }
    function getSaleInfo(
        address collection,
        uint256 tokenId
    ) external view returns (SaleInfo memory) {
        return _nftInfoForSale[collection][tokenId];
    }

    function getCollectionInfo(address collection) external view returns(CollectionInfo memory) {
        return _addedCollections[collection];
    }
    function isOwner(address _isOwner) internal view {
        if (!(_isOwner == msg.sender)) {
            revert Marketplace__NotOwner();
        }
    }
    function tokenOwner(
        address collection,
        uint256 tokenId
    ) internal view returns (address) {
        return IERC721(collection).ownerOf(tokenId);
    }
}
