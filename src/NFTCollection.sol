// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title NFTCollection - A contract for minting NFTs
/// @notice This contract is used to mint NFTs
contract NFTCollection is ERC721URIStorage {
   
    error NFTCollection__MaxSupplyReached();
    error NFTCollection__NotMarketplaceContract();

    uint256 private _tokenIdentifiers;
    address public marketplaceContract;
    uint256 public MAX_SUPPLY = 2 ** 256 - 1;
    
    modifier onlyMarketplaceContract() {
        if(msg.sender != marketplaceContract){
            revert NFTCollection__NotMarketplaceContract();
        }
        _;
    }
    /// @dev This function is used to initialize the contract, it can only be called once
    /// @param _name The name of the NFT collection
    /// @param _symbol The symbol of the NFT collection
    /// @param _maxSupply The maximum supply of collection
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        marketplaceContract = msg.sender;
    }

    /// @dev This function is used to mint NFTs, it can only be called by the marketplace contract
    /// @param _tokenURI The URI of the token to mint
    /// @param _to The address of the recipient
    /// @return The token ID of the newly minted NFT
    function MintNFT(
        string memory _tokenURI,
        address _to
    ) external onlyMarketplaceContract returns (uint256) {
        if (_tokenIdentifiers >= MAX_SUPPLY) {
            revert NFTCollection__MaxSupplyReached();
        }
        _tokenIdentifiers++;
        uint256 newTokenId = _tokenIdentifiers;
        
        bytes memory stringURI = bytes(_tokenURI);
        if (stringURI.length == 0) {
            revert("Token URI cannot be empty");
        }
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        return newTokenId;
    }
}
