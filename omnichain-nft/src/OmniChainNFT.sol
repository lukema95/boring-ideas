// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";


contract OmniChainNFT is ERC721, ZetaInteractor, ZetaReceiver {
    error InvalidMessageType();

    event CrossChainMessageEvent(uint256);
    event CrossChainMessageRevertedEvent(uint256);

    uint256 public immutable CHAIN_ID;

    uint256 public constant MINT_CHAIN_ID = 5;

    bytes32 public constant CROSS_CHAIN_MESSAGE_MESSAGE_TYPE =
        keccak256("CROSS_CHAIN_CROSS_CHAIN_MESSAGE");
    ZetaTokenConsumer private immutable _zetaConsumer;
    IERC20 internal immutable _zetaToken;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public totalSupply = 0;

    mapping(uint256 => bool) public frozenTokens; 

    modifier onlyNotFrozen(uint256 _tokenId) {
        require(!frozenTokens[_tokenId], "Token is frozen");
        _;
    }

    constructor(
        address connectorAddress,
        address zetaTokenAddress,
        address zetaConsumerAddress,
        string memory _name, 
        string memory _symbol,
        uint256 _chainId
    ) ZetaInteractor(connectorAddress) ERC721(_name, _symbol){
        _zetaToken = IERC20(zetaTokenAddress);
        _zetaConsumer = ZetaTokenConsumer(zetaConsumerAddress);
        CHAIN_ID = _chainId;
    }

    function sendMessage(
        uint256 destinationChainId,
        uint256 tokenId
    ) external payable onlyNotFrozen(tokenId) {
        if (!_isValidChainId(destinationChainId))
            revert InvalidDestinationChainId();
        
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");

        uint256 crossChainGas = 2 * (10 ** 18);
        uint256 zetaValueAndGas = _zetaConsumer.getZetaFromEth{
            value: msg.value
        }(address(this), crossChainGas);
        _zetaToken.approve(address(connector), zetaValueAndGas);

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                destinationGasLimit: 300000,
                message: abi.encode(CROSS_CHAIN_MESSAGE_MESSAGE_TYPE, msg.sender, tokenId),
                zetaValueAndGas: zetaValueAndGas,
                zetaParams: abi.encode("")
            })
        );
        
        // Freeze the token
        freeze(tokenId);
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override isValidMessageCall(zetaMessage) {
        (bytes32 messageType, address sender, uint256 tokenId) = abi.decode(
            zetaMessage.message,
            (bytes32, address, uint256)
        );

        if (messageType != CROSS_CHAIN_MESSAGE_MESSAGE_TYPE)
            revert InvalidMessageType();

        // If the token is frozen, unfreeze it
        // Otherwise, mint the token to the user
        if (isFrozen(tokenId)) {
            unfreeze(sender, tokenId);
        } else {
            _safeMint(sender, tokenId);
        }

        emit CrossChainMessageEvent(tokenId);
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {
        (bytes32 messageType, uint256 tokenId) = abi.decode(
            zetaRevert.message,
            (bytes32, uint256)
        );

        if (messageType != CROSS_CHAIN_MESSAGE_MESSAGE_TYPE)
            revert InvalidMessageType();

        // Mint the token back to the user
        _safeMint(msg.sender, tokenId);

        emit CrossChainMessageRevertedEvent(tokenId);
    }

    function mint() external {
        // Only allow minting on the MINT_CHAIN_ID, because we want to avoid minting on multiple chains
        require(CHAIN_ID == MINT_CHAIN_ID, "Only allow minting on the MINT_CHAIN_ID");
        uint256 _tokenId = totalSupply;
        require(_tokenId < MAX_SUPPLY, "Max supply reached");
        _safeMint(msg.sender, _tokenId);
        totalSupply++;
    }

    function burn(uint256 _tokenId) external onlyNotFrozen(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        _burn(_tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyNotFrozen(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyNotFrozen(tokenId) {
        require(!frozenTokens[tokenId], "Token is frozen");
        super.safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override onlyNotFrozen(tokenId) {
        super.approve(to, tokenId);
    }

    function freeze(uint256 _tokenId) internal onlyNotFrozen(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        // delete _tokenApprovals[tokenId];
        frozenTokens[_tokenId] = true;
    }

    function unfreeze(address to, uint256 _tokenId) internal {
        require(frozenTokens[_tokenId], "Token already unfrozen");
        frozenTokens[_tokenId] = false;
        
        address owner = ownerOf(_tokenId);
        _transfer(owner, to, _tokenId);
    }

    function isFrozen(uint256 _tokenId) public view returns (bool) {
        return frozenTokens[_tokenId];
    }
}
