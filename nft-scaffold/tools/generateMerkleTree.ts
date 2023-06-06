import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

export function generateMerkleTree(whitelistAddress: Array<string>) {
  const leafNodes = whitelistAddress?.map((addr) => keccak256(addr))
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
  return merkleTree
}