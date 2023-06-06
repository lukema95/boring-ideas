// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Fireworks
 * @author lukema95
 * @notice Fireworks is used to burn the user's NFT and give rewards accordingly
 */
contract Fireworks is Ownable, ReentrancyGuard, IERC165, IERC721Receiver, IERC1155Receiver {

  using ERC165Checker for address;

  bytes4 public constant IID_IERC165 = type(IERC165).interfaceId;
  bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
  bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == IID_IERC165;
  }

  function isERC1155(address tokenAddress) internal view returns (bool) {
    return tokenAddress.supportsInterface(IID_IERC1155);
  }    
    
  function isERC721(address tokenAddress) internal view returns (bool) {
    return tokenAddress.supportsInterface(IID_IERC721);
  }

  /**
  * @dev always returns `IERC721Receiver.onERC721Received.selector`.
  * more details: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol
  */
  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
  * @dev always returns `IERC1155Receiver.onERC1155Received.selector`.
  * more details: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol
  * 
  */
  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  /**
  * @dev always returns `IERC1155Receiver.onERC1155BatchReceived.selector`.
  * more details: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol
  */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public virtual override returns (bytes4)
  {
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev External function to burn ERC721 or ERC1155 NFT
   * 
   * @param tokenContract The address of the NFT contract to be burned
   * @param tokenIds The ids of the NFT to be burn
   * @param amounts The amounts of NFT to be burn, null if it is an ERC721 contract
   */
  function burn(address tokenContract, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
    require(_checkContract(tokenContract), "contract address error");
    require(_verifyApprove(tokenContract), "not authorized by contract");
    _transferToken(tokenContract, msg.sender, address(this), tokenIds, amounts);
  }

  /**
   * @dev External function to withdraw NFT of contract
   * 
   * @param tokenContract The address of the contract to be withdrawn
   * @param to The address to receive the NFT
   * @param tokenIds The ids of the NFT to be withdraw
   * @param amounts The amounts of NFT to be withdraw, null if it is an ERC721 contract
   */
  function withdraw(address tokenContract, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external onlyOwner nonReentrant {
    require(_checkContract(tokenContract), "contract address error");
    _transferToken(tokenContract, address(this), to, tokenIds, amounts);
  }

/**
 * @dev Internal function to transfer ERC1155 NFT or ERC721 token from sender to this contract
 * 
 * @param tokenContract The ERC721 or ERC1155 contract to be transfer
 * @param from The sender of the transfer
 * @param to The address to receive the transfer
 * @param tokenIds The ids of the NFT to be transfer
 * @param amounts The amounts of NFT to be transfer, null if it is an ERC721 contract
 */
  function _transferToken(address tokenContract, address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) internal {
    if (isERC721(tokenContract)) {
      for(uint256 i = 0; i < tokenIds.length; i++) {
        IERC721(tokenContract).safeTransferFrom(from, to, tokenIds[i]);
      }
    }else {
      IERC1155(tokenContract).safeBatchTransferFrom(from, to, tokenIds, amounts, "");
    }
  }

  /**
   * @dev Internal view function to verify that the token contract is authorized to the contract
   * 
   * @param tokenContract The address of the contract to verify
   * 
   * @return isApprove A boolean indicating whether the sender's ERC721/ERC1155 
   *                   contract is authorized to this contract
   */
  function _verifyApprove(address tokenContract) internal view returns(bool isApprove) {
    if (isERC721(tokenContract)) {
      isApprove = IERC721(tokenContract).isApprovedForAll(msg.sender, address(this));
      return isApprove;
    }else {
      isApprove = IERC1155(tokenContract).isApprovedForAll(msg.sender, address(this));
      return isApprove;
    }

  }

  /**
   * @dev Internal view function to check whether the contract is ERC721 or ERC1155
   * 
   * @param tokenAddress The address of the contract to check
   * 
   * @return isNFTContract A boolean indicating whether the contract is ERC721 or ERC1155
   */
  function _checkContract(address tokenAddress) internal view returns(bool isNFTContract) {
    isNFTContract = isERC1155(tokenAddress) || isERC721(tokenAddress);
    return isNFTContract;
  }
  
}