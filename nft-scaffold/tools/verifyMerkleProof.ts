import keccak256 from 'keccak256'
import {generateMerkleRoot} from './generateMerkleRoot';

export function verifyMerkleProof(merkleTree: any, address: string){
  const root = generateMerkleRoot(merkleTree);
  const leaf = keccak256(address);
  const proof = merkleTree.getHexProof(leaf);
  const isVerified = merkleTree.verify(proof, leaf, root);
  console.log('verify result', isVerified);
  return isVerified  
}