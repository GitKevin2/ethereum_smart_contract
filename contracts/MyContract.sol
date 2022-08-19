// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'hardhat/console.sol';
import './helpers/NodeList.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract MyContract is ERC721, IERC721Receiver {
    struct InfoNFT {
        uint256 id;
        uint256 value;
        uint256 amountPaid;
        address client;
        bool hasPaid;
    }

    using Nodes for NodeList;
    event Signature(address indexed signer, uint256 tokenId);
    event Deposit(uint256 indexed tokenId, address client, uint256 amount);
    event Transaction();

    address payable internal immutable OWNER;
    uint private immutable REQUIRED_TO_SIGN;
    NodeList private _signers;
    mapping(uint256 => uint) _signatures;
    mapping(uint256 => mapping(address => bool)) _hasSigned;
    mapping(uint256 => InfoNFT) _info;

    modifier approved(uint256 tokenId) {
        require(_signatures[tokenId] >= REQUIRED_TO_SIGN, "not enough approvals");
        _;
    }

    modifier checkSender(address addr, bool isSender) {
        require((addr == msg.sender) == isSender, "incorrect sender in use");
        _;
    }

    constructor(address[] memory owners, uint requiredToSign) ERC721("MyContract", "MC") {
        REQUIRED_TO_SIGN = requiredToSign <= owners.length ? requiredToSign : owners.length;
        _signers.push(owners);
        //*/
        OWNER = payable(msg.sender);
    }

    receive() external payable {
        console.log("Received: %d wei", msg.value);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://wallet.kevinjong.co.nz/nfts/";
    }

    function safeMint(address to, uint256 tokenId, uint256 value) public {
        _safeMint(OWNER, tokenId);
        _info[tokenId] = infoNFT(tokenId, to, value);
    }

    function safeMintWithApproved(address to, uint256 tokenId, uint256 value, address approvedSigner) public {
        safeMint(to, tokenId, value);
        require(_signers.has(approvedSigner), "must be a valid company signer");
        approve(approvedSigner, tokenId);
    }

    function safeTransfer(uint256 tokenId) public approved(tokenId) {
        require(_exists(tokenId), "token doesn't exist");
        require(ownerOf(tokenId) == OWNER, "can only transfer tokens belonging to the multi-sig wallet");
        require(isPaid(_info[tokenId]), "loan not paid off");

        safeTransferFrom(OWNER, _info[tokenId].client, tokenId);
    }

    function signTransaction(uint256 tokenId) external {
        bool isSigner = clientOf(tokenId) == msg.sender || _signers.has(msg.sender);
        if (isSigner) _signatures[tokenId]++;
        emit Signature(isSigner ? msg.sender : address(0), tokenId);
    }

    function deposit(uint256 tokenId) public payable approved(tokenId) checkSender(OWNER, false) {
        require (msg.value > 0, "no payment has been sent.");

        uint256 amount = msg.value;
        (bool success, ) = OWNER.call{value: amount}("");
        require (success, "transaction failed");
        InfoNFT storage token = _info[tokenId];
        token.amountPaid += amount;
        if (isPaid(token)) token.hasPaid = true;
        delete _signatures[tokenId];
        emit Deposit(tokenId, token.client, amount);
    }

    function changeClient(uint256 tokenId, address newClient) external {
        require(_signers.has(msg.sender), "only signers to this wallet can change clients");
        _info[tokenId].client = newClient;
    }

    function addSigner(address signer) public {
        _signers.push(signer);
    }

    function removeSigner(address signer) public {
        _signers.remove(signer);
    }

    /** Returns the signer addresses of the multi-sig wallet as an array. */
    function getCompanySigners() public view returns (address[] memory) {
        return _signers.toArray();
    }

    function amountPaidFor(uint256 tokenId) public view returns (uint256) {
        return _info[tokenId].amountPaid;
    }

    function contains(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function clientOf(uint256 tokenId) public view returns (address) {
        return _info[tokenId].client;
    }

    function isPaid(uint256 tokenId) external view returns(bool) {
        InfoNFT memory token = _info[tokenId];
        return isPaid(token);
    }

    function isPaid(InfoNFT memory token) internal pure returns (bool) {
        return token.amountPaid >= token.value;
    }

    function infoNFT(uint256 tokenId, address to, uint256 value) internal pure returns (InfoNFT memory) {
        return InfoNFT({id:tokenId, client:to, value:value, amountPaid:0, hasPaid:false});
    }

    function getNftInfo(uint256 tokenId) external view returns (uint256 id, address client, uint256 value, uint256 amountPaid, bool hasPaid) {
        InfoNFT storage nft = _info[tokenId];
        return (nft.id, nft.client, nft.value, nft.amountPaid, nft.hasPaid); 
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
    }
}