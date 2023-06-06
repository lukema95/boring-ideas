import * as React from 'react'
import { useAccount } from 'wagmi'
import Image from 'next/image'

import { Account, Connect, Mint, Info } from '../components'
import { useIsMounted } from '../hooks'
import { generateMerkleTree } from '../tools'
import { whitelist } from '../config'
import styles from './styles.module.css'

const merkleTree = generateMerkleTree(whitelist)

function Page() {
  const isMounted = useIsMounted()
  const { isConnected } = useAccount()

  return (
    <>
    <div className={styles.img}>
    <Image 
        src="/home.jpeg"
        alt="Picture of the project"
        width={600}
        height={600}
      />
      <Info/>
      <Connect />
      {isMounted && isConnected && (
        <>
          <Account />
        </>
      )}
      <Mint
      merkleTree = {merkleTree} 
      quantity = {1}
      />
    </div>
      
    </>
  )
}

export default Page
