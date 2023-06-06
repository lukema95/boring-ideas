// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CodeDoge is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public maxPerAddressMint;             // 每个钱包的最大Mint数量
    uint256 public maxPerWhitelistAddressMint;    // 白名单最大允许Mint数量
    uint256 public collectionSize;                // 最大供应量
    uint256 public amountForDevs;                 // 提供给开发者的最大数量
    uint256 public amountForWhitelist;            // 提供给白名单的最大数量
    bytes32 private merkleRoot;                             // 白名单地址的Merkle树根
    uint8   public phase;                                   // 0: 开发者mint，1: 白名单mint， 2: 公售mint

    struct SaleConfig {
        uint32 whitelistSaleStartTime;     // 白名单销售开始时间
        uint32 publicSaleStartTime;        // 公售开始时间
        uint64 whitelistPrice;             // 白名单Mint价格
        uint64 publicPrice;                // 公售Mint价格
        uint32 publicSaleKey;              // 公售MintKey
    }

    SaleConfig public saleConfig;

    function initialize(
        uint256 maxPerAddressMint_,
        uint256 maxPerWhitelistAddressMint_,
        uint256 collectionSize_,
        uint256 amountForDevs_,
        uint256 amountForWhitelist_
    ) 
        initializerERC721A 
        initializer 
        public 
    {

        __ERC721A_init('CodeDoge', 'CODEDOGE');
        __Ownable_init();

        maxPerAddressMint = maxPerAddressMint_;
        maxPerWhitelistAddressMint = maxPerWhitelistAddressMint_;
        amountForDevs = amountForDevs_;
        amountForWhitelist = amountForWhitelist_;
        collectionSize = collectionSize_;
        require(
          amountForWhitelist_ <= collectionSize_,
          "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity, uint256 callerPublicSaleKey, bytes32[] calldata _merkleProof) external payable callerIsUser {
        if(phase == 0) {
          devMint(quantity);
        }else if(phase == 1) {
          whitelistMint(quantity, _merkleProof);
        }else if(phase == 2) {
          publicSaleMint(quantity, callerPublicSaleKey);
        }else {
          revert("phase error");
        }
    }

    /**
     * 白名单Mint
     */
    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) internal {
        uint256 _saleStartTime = uint256(saleConfig.whitelistSaleStartTime);
        require(
          _saleStartTime != 0 && block.timestamp >= _saleStartTime,
          "sale has not started yet"
        );
        uint256 price = uint256(saleConfig.whitelistPrice);
        require(price != 0, "whitelist sale has not begun yet");
        require(
          numberMinted(msg.sender) + quantity <= maxPerWhitelistAddressMint,
          "can not mint this many"
        );
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(isAllowList(msg.sender, _merkleProof), "not eligible for whitelist mint");
        _safeMint(msg.sender, 1);
        refundIfOver(price*quantity);
    }

  /**
   * 公售Mint
   */
  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey) internal {
    require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
    SaleConfig memory config = saleConfig;
    uint256 publicSaleKey = uint256(config.publicSaleKey);
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    require(
      publicSaleKey == callerPublicSaleKey,
      "called with incorrect public sale key"
    );

    require(
      isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

    /**
     * 开发者Mint
     */
    function devMint(uint256 quantity) internal onlyOwner {
        require(
          totalSupply() + quantity <= amountForDevs,
          "too many already minted before dev mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
          payable(msg.sender).transfer(msg.value - price);
        }
    }

    // 判断是否已经开始公售
    function isPublicSaleOn(
        uint256 publicPriceWei,
        uint256 publicSaleKey,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
      // 同时满足以下三个条件后才可开始公售Mint
        return
            publicPriceWei != 0 &&
            publicSaleKey != 0 &&
            block.timestamp >= publicSaleStartTime;
    }

  // 设置公售和白单Mint配置
    function setPublicAndWhitelistSaleInfo(
        uint64 whitelistPriceWei,
        uint64 publicPriceWei,
        uint32 whitelistSaleTime,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
          whitelistSaleTime,
          publicSaleStartTime,
          whitelistPriceWei,
          publicPriceWei,
          saleConfig.publicSaleKey
        );
    }

    function setPhase(uint8 _phase) external onlyOwner {
        phase = _phase;
    }

    // 设置公售开SaleKey
    function setPublicSaleKey(uint32 key) external onlyOwner {
        saleConfig.publicSaleKey = key;
    }

    // 设置白单销售开始时间
    function setWhitelistSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.whitelistSaleStartTime = timestamp;
    }

    // 设置公售开始时间
    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    // 设置白单销售价格
    function setWhitelistSalePrice(uint64 whitelistPriceWei) external onlyOwner {
        saleConfig.whitelistPrice = whitelistPriceWei;
    }

    // 设置公售价格
    function setPublicSalePrice(uint64 publicPriceWei) external onlyOwner {
        saleConfig.publicPrice = publicPriceWei;
    }

    // 设置Merkle树根，MerkleRoot使用所有白名单来计算
    function setMerkleRoot (bytes32 _merkleRoot) public onlyOwner {              
        merkleRoot = _merkleRoot;
    }

    // 使用用户地址和该地址对应的Merkle证明来验证账户是否在白名单中
    function isAllowList(address _address, bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        return true; 
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // 取走合约中的资产
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    //   _setOwnersExplicit(quantity);
    // }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}