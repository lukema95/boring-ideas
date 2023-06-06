import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { generateMerkleProof, generateMerkleTree } from '../tools/index'

describe("CodeDoge", function() {
  async function deployFixture(){

    const maxPerAddressMint = 2;
    const maxPerWhitelistAddressMint = 2;
    const collectionSize = 10000;
    const amountForDevs = 200;
    const amountForWhitelist = 4000;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const CodeDoge = await ethers.getContractFactory("CodeDoge");
    const codeDoge = await upgrades.deployProxy(CodeDoge, [maxPerAddressMint, maxPerWhitelistAddressMint, collectionSize, amountForDevs, amountForWhitelist]);
  
    await codeDoge.deployed();
    const timeNow = await time.latest()

    // set whitelist sale config
    await codeDoge.setWhitelistSaleStartTime(timeNow)
    await codeDoge.setWhitelistSalePrice(1)

    // set public sale config
    await codeDoge.setPublicSaleStartTime(timeNow)
    await codeDoge.setPublicSalePrice(2)
    await codeDoge.setPublicSaleKey(1)

    // set merkle tree root
    var whitelist = [otherAccount.address, owner.address, "0x87174E23BD6f7C08300feBB704D4C02082804388"]
    var merkleTree = generateMerkleTree(whitelist)
    const merkleTreeRoot = merkleTree.getHexRoot()
    const merkleTreeProof = generateMerkleProof(merkleTree, otherAccount.address)
    
    await codeDoge.setMerkleRoot(merkleTreeRoot)
    
    return { codeDoge, owner, otherAccount, merkleTreeProof, maxPerAddressMint, maxPerWhitelistAddressMint, collectionSize, amountForDevs, amountForWhitelist };
  }

  describe("Deployments", function () { 
    it("Should set the right amount", async function() {

      const { codeDoge, maxPerAddressMint, maxPerWhitelistAddressMint, collectionSize, amountForDevs, amountForWhitelist } = await loadFixture(deployFixture);

      expect(await codeDoge.maxPerAddressMint()).to.equal(maxPerAddressMint);
      expect(await codeDoge.maxPerWhitelistAddressMint()).to.equal(maxPerWhitelistAddressMint);
      expect(await codeDoge.collectionSize()).to.equal(collectionSize);
      expect(await codeDoge.amountForDevs()).to.equal(amountForDevs);
      expect(await codeDoge.amountForWhitelist()).to.equal(amountForWhitelist);
    })

    it("Should set the right phase", async function() {
      const { codeDoge } = await loadFixture(deployFixture);
      expect(await codeDoge.phase()).to.equal(0);
    })

    it("Should set the right owner", async function () {
      const { codeDoge, owner } = await loadFixture(deployFixture);

      expect(await codeDoge.owner()).to.equal(owner.address);
    });
  })

  describe("Mints", async function () {
    it("Should success if minted by dev on phase 0", async function() {
      const { codeDoge, owner } = await loadFixture(deployFixture)
      await codeDoge.mint(100, 0, [])
      expect(await codeDoge.balanceOf(owner.address)).to.equal(100)
    })

    it("Should fail if minted on phase 0 with exceeded quantity", async function() {
      const { codeDoge, owner } = await loadFixture(deployFixture)
      await expect(codeDoge.mint(201, 0, [])).to.be.revertedWith("too many already minted before dev mint")
    })

    it("Should fail if minted by other account on phase 0", async function() {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      await expect(codeDoge.connect(otherAccount).mint(100, 0, [])).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it("Should success if minted by other account on phase 1", async function() {
      const { codeDoge, otherAccount, merkleTreeProof } = await loadFixture(deployFixture)

      await codeDoge.setPhase(1)

      await codeDoge.connect(otherAccount).mint(1, 0, merkleTreeProof, {value: 1})
      expect(await codeDoge.balanceOf(otherAccount.address)).to.be.equal(1)
    })

    it("Should fail if minted on phase 1 with incorret merkle tree proof", async function() {
      const { codeDoge, owner, otherAccount, merkleTreeProof } = await loadFixture(deployFixture)
      await codeDoge.setPhase(1)
      const incorrectProof=["0xb377c023e265559703a07076c16283beec72280f69a0e38d6a69fd1f84d7dc05","0xb377c023e265559703a07076c16283beec72280f69a0e38d6a69fd1f84d7dc05"]
      await expect(codeDoge.mint(1, 0, merkleTreeProof, {value: 1})).to.be.revertedWith("Incorrect proof")
      await expect(codeDoge.connect(otherAccount).mint(1, 0, incorrectProof, {value: 1})).to.be.revertedWith("Incorrect proof")
    })

    it("Should fail if minted on phase 1 with wrong time", async function(){
      const { codeDoge, otherAccount, merkleTreeProof } = await loadFixture(deployFixture)
      const timeNow = await time.latest()

      await codeDoge.setWhitelistSaleStartTime(timeNow+100000)
      await codeDoge.setPhase(1)
      await expect(codeDoge.connect(otherAccount).mint(1, 0, merkleTreeProof, {value: 2})).to.be.revertedWith("sale has not started yet")
    })

    it("Should fail if minted on phase 1 with insufficient eth value", async function() {
      const { codeDoge, otherAccount, merkleTreeProof } = await loadFixture(deployFixture)
      await codeDoge.setPhase(1)
      await expect(codeDoge.connect(otherAccount).mint(2, 0, merkleTreeProof, {value: 1})).to.be.revertedWith("Need to send more ETH.")
    })

    it("Should fail if minted on phase 1 with exceeded quantity", async function() {
      const { codeDoge, otherAccount, merkleTreeProof } = await loadFixture(deployFixture)
      await codeDoge.setPhase(1)
      await codeDoge.connect(otherAccount).mint(1, 0, merkleTreeProof, {value: 2})
      await expect(codeDoge.connect(otherAccount).mint(2, 0, merkleTreeProof, {value: 2})).to.be.revertedWith("can not mint this many")
    })

    it("Should success if minted on phase 2", async function() {
      const { codeDoge, owner, otherAccount } = await loadFixture(deployFixture)
      await codeDoge.setPhase(2)
      await codeDoge.connect(otherAccount).mint(2, 1, [], {value: 4})
      expect(await codeDoge.balanceOf(otherAccount.address)).to.be.equal(2)
    })

    it("Should fail if minted on phase 2 with wrong time", async function() {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      const timeNow = await time.latest()
      await codeDoge.setPhase(2)
      await codeDoge.setPublicSaleStartTime(timeNow+1000)
      await expect(codeDoge.connect(otherAccount).mint(2, 1, [], {value: 4})).to.be.revertedWith("public sale has not begun yet")
    })

    it("Should fail if minted on phase 2 with incorrect public sale key", async function() {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      await codeDoge.setPhase(2)
      await expect(codeDoge.connect(otherAccount).mint(2, 0, [], {value: 4})).to.be.revertedWith("called with incorrect public sale key")
    })

    it("Should fail if minted on phase 2 with insufficient eth value", async function() {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      await codeDoge.setPhase(2)
      await expect(codeDoge.connect(otherAccount).mint(2, 1, [], {value: 2})).to.be.revertedWith("Need to send more ETH.")
    })

    it("Should fail if minted on phase 2 with exceeded quantity", async function() {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      await codeDoge.setPhase(2)
      await expect(codeDoge.connect(otherAccount).mint(3, 1, [], {value: 2})).to.be.revertedWith("can not mint this many")
    })


  })

  describe("Withdraws", async function () {
    it("Should success if withdrawed money by owner", async function () {
      const { codeDoge, owner, otherAccount } = await loadFixture(deployFixture)
      // const balance = await owner.getBalance()
      // const tx = {
      //   to: codeDoge.address,
      //   value: 100
      // }
      // const provider = ethers.getDefaultProvider();
      // const balance1 = await provider.getBalance(codeDoge.address)
      // console.log("balance1 is %s", balance1)
      // await codeDoge.mint(1, 1, [], {value: 1000})
      // const balance2 = await provider.getBalance(codeDoge.address)
      // console.log("balance2 is %s", balance2)
      // expect(await provider.getBalance(codeDoge.address)).to.be.equal(1000)
      // TODO 完成余额测试
      expect(await codeDoge.withdrawMoney()).not.be.reverted
      // expect(await provider.getBalance(codeDoge.address)).to.be.equal(0)
    })

    it("Should fail if withdrawed money by owner", async function () {
      const { codeDoge, otherAccount } = await loadFixture(deployFixture)
      await expect(codeDoge.connect(otherAccount).withdrawMoney()).to.be.revertedWith("Ownable: caller is not the owner")
    })
  })

  describe("Ownerships", async function () {
    it("Should success if transferred ownership by owner", async function () {
      const { codeDoge, otherAccount} = await loadFixture(deployFixture)
      await codeDoge.transferOwnership(otherAccount.address)
      expect(await codeDoge.owner()).to.equal(otherAccount.address)
    })

    it("Should fail if transferred ownership by other account", async function () {
      const { codeDoge, otherAccount} = await loadFixture(deployFixture)
      await expect(codeDoge.connect(otherAccount).transferOwnership(otherAccount.address)).to.be.revertedWith("Ownable: caller is not the owner")
    })
  })

  describe("Transfers", async function () {
    it("Should success if transferred token by token owner", async function () {
      const { codeDoge, owner, otherAccount} = await loadFixture(deployFixture)
      await codeDoge.mint(1, 1, [])
      expect(await codeDoge.ownerOf(0)).to.equal(owner.address)

      await codeDoge.transferFrom(owner.address, otherAccount.address, 0)
      expect(await codeDoge.ownerOf(0)).to.equal(otherAccount.address)
    })

    // it("Should fail if transferred token by incorrect owner", async function () {
    //   const { codeDoge, owner, otherAccount} = await loadFixture(deployFixture)
    //   await codeDoge.mint(1, 1, [])
    //   expect(await codeDoge.ownerOf(0)).to.equal(owner.address)
      
    //   await expect(codeDoge.transferFrom(otherAccount.address, otherAccount.address, 0)).to.be.revertedWith("ERC721A: transfer from incorrect owner")
      
    // })
  })

})