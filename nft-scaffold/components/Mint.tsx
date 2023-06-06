import { useAccount, 
        useProvider, 
        useContractWrite, 
        usePrepareContractWrite,
        useWaitForTransaction, 
       } from 'wagmi'

import { generateMerkleProof } from '../tools'
import { contractConfig } from '../config'

export function Mint(props: any){
  const { address, connector, isConnected } = useAccount()
  console.log("address is", address)
  const provider = useProvider()
  const contractABI = contractConfig.abi
  const contractAddress = contractConfig.address
  const phase = contractConfig.phase
  const merkleProof = phase == 1 ? generateMerkleProof(props.merkleTree, address??'') : []
  const publicSaleKey = phase == 2 ? contractConfig.publicSaleKey : 0
  console.log("contractAddress is " + contractAddress, "quantity is " + props.quantity, "publicSaleKey is " + publicSaleKey, "merkleProof is " + merkleProof)
  const { 
    config,
    error: prepareError,
    isError: isPrepareError,
  } = usePrepareContractWrite({
    addressOrName: contractAddress,
    contractInterface: contractABI,
    functionName: 'mint',
    args: [props.quantity, publicSaleKey, merkleProof],
  })
  

  const { data, error, isError, write } = useContractWrite(config)

  // Wait tx result
  const { isLoading, isSuccess } = useWaitForTransaction({
    hash: data?.hash,
  })

  return (
    <div>
      <button onClick={() => write?.()}>
        {isLoading ? 'Minting...' : 'Mint'}
      </button>
      {isSuccess && (
        <div>
          Successfully minted your NFT!
          <div>
            <a href={`https://etherscan.io/tx/${data?.hash}`}>Etherscan</a>
          </div>
        </div>
      )}
      {(isPrepareError || isError) && (
        <div>Error: {(prepareError || error)?.message}</div>
      )}
    </div>
  )
}