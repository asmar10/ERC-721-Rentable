/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC4907.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error preSaleEnded();
error insufficientFunds();
error saleNotStarted();
error limitReached();
error userLimitReached();
error amountCantBeMoreThan3();
error ownerLimitReached();

contract nft is ERC721URIStorage, Ownable, IERC4907 {

    bytes32 private merkleRoot;
    using Strings for uint256;
    IERC20 token;
    uint256 tokenId = 50;
    bool public saleStatus;
    bool public preSaleStatus;
    uint256 public preSaleEndTime;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public preSaleStartTime;
    uint256 public limitOfUserMint = 3;
    uint256 public totalSupply = 1691;
    uint256 public totalMintedByWhitelistedUsers;
    uint256 public totalMintedByOwner;
    uint256 public totalMintedDuringSale;
    uint256 public preSalePrice = 0.027 ether;
    uint256 public salePrice = 0.1691 ether;
    bool private isRevealed;
    string private URI;
    uint256 public ownerLimit=50;
    mapping(address => bool) public hasWhiteListUserMinted;
    mapping(address => uint) public userCurrentMinted;
    uint256 public currentOverallSupply; 

    /*RENTAL*/
    struct UserInfo {
        address user;
        uint64 expires; 
    }
    mapping(uint256 => UserInfo) internal _users;

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC4907: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = uint64(block.timestamp + expires);
        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function userExpires(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {   if(block.timestamp>_users[tokenId].expires){
        return 0;
    }   else{
        return _users[tokenId].expires;
    }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }

    /*RENTAL*/
    constructor(address _token,string memory _URI,bytes32 _merkleRoot) ERC721("MyToken", "MTK") 
    {
        merkleRoot = _merkleRoot;
        URI = _URI;
        token = IERC20(_token);
    }

    function preSaleMint(/*uint quantity,*/ bytes32[] calldata merkleProof) public {
        /*uint quantity = 1;*/
        bytes32 node = keccak256(abi.encodePacked(msg.sender /*, quantity*/));/*quantity is set to 1 we can take this in parameter*/
        require(MerkleProof.verify(merkleProof, merkleRoot, node),"invalid proof");
        require(preSaleStatus == true, "Not Started");
        if (hasWhiteListUserMinted[msg.sender] == false) {
            if (block.timestamp < preSaleEndTime) {
                if (getBalance(msg.sender) >= preSalePrice) {
                    totalMintedByWhitelistedUsers++;
                    hasWhiteListUserMinted[msg.sender]=true;
                    tokenId++;
                    token.transferFrom(msg.sender, address(this), preSalePrice);
                    _mint(msg.sender, tokenId);
                    currentOverallSupply++;
                } else {
                    revert insufficientFunds();
                }
            } else {
                revert preSaleEnded();
            }
        } else {
            revert userLimitReached();
        }
    }

    function saleMint(uint256 amount) public {
        require(saleStatus == true, "notStarted");
        if (saleEndTime > block.timestamp) {
            if (tokenId < totalSupply) {
                if ((userCurrentMinted[msg.sender]+amount)<=limitOfUserMint) {
                    if ((amount * salePrice) <= getBalance(msg.sender)) {
                        token.transferFrom(msg.sender,address(this),salePrice);
                        for (uint256 i = 0; i < amount; i++) {
                            tokenId++;
                            _mint(msg.sender, tokenId);
                            currentOverallSupply++;
                            totalMintedDuringSale++;
                            userCurrentMinted[msg.sender]++;
                        }
                    } else {
                        revert insufficientFunds();
                    }
                } else {
                    revert amountCantBeMoreThan3();
                }
            } else {
                revert limitReached();
            }
        } else {
            revert saleNotStarted();
        }
    }

    function mintForOwner(uint256 quantity) public onlyOwner {
        if((totalMintedByOwner+quantity)<=ownerLimit){
             for (uint256 i = 1; i <= quantity; i++) {
            totalMintedByOwner++;
            _mint(msg.sender, totalMintedByOwner);
            currentOverallSupply++;
        }
        }
        else{
            revert ownerLimitReached();
        }  
    }

    function startPreSale(uint256 preSaleDuration) public onlyOwner {
        preSaleStatus = true;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + preSaleDuration;
    }

    function endPreSale() public onlyOwner {
        preSaleStatus = false;
        preSaleStartTime = 0;
        preSaleEndTime = 0;
    }

    function startSale(uint256 saleDuration) public onlyOwner {
        saleStatus = true;
        saleStartTime = block.timestamp;
        saleEndTime = saleStartTime + saleDuration;
    }

    function endSale() public onlyOwner {
        saleStatus = false;
        saleStartTime = 0;
        saleEndTime = 0;
    }

    function getBalance(address add) public view returns (uint256) {
        return token.balanceOf(add);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        if (!isRevealed) {
            return
                bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, "URI"))
                    : "";
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }
} /*NFT*/
