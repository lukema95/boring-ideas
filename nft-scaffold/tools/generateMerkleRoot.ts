export function generateMerkleRoot(merkleTree: any) {
  const merkleRoot = merkleTree.getHexRoot()
  // console.log('merkleTree', merkleTree.toString())
  return merkleRoot
}