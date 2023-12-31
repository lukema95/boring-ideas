const ethers = require('ethers');

const contractABI = [
  'function inscribe(uint256 amount)',
  'function totalSupply() view returns (uint256)',
  'function mintingAlgo(uint64 currentBlockNum, uint256 amount) view returns (bool)',
  {"inputs":[],"name":"lastBlock","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"initialBlockNum","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"stateMutability":"view","type":"function"},
]; 

const contractAddress = '0x8d06EB063b00cfb2f96171af184C73F76Fe1d41F';

// 换成你的Alchemy API Key
const provider = new ethers.JsonRpcProvider('https://eth-mainnet.g.alchemy.com/v2/your-api-key')

// const newWallet = ethers.Wallet.createRandom();
// console.log(`新钱包地址: ${newWallet.address}`);
// console.log(`新钱包私钥: ${newWallet.privateKey}`);

// 替换成你的钱包私钥
const privateKey = 'your-private-key';

const wallet = new ethers.Wallet(privateKey, provider);

const contract = new ethers.Contract(contractAddress, contractABI, wallet);


async function mintingAlgo(amount, initialBlockNum, currentBlockNum, totalSupply) {
  const amtDifficulty = 10;
  const blockDifficulty = 1000;
  const totalSupplyDifficulty = 100000;

  const randomString = ethers.solidityPackedKeccak256
    (['uint64', 'uint256', 'address', 'uint128'],
    [currentBlockNum, amount, wallet.address, totalSupply + 1]
    );

  const random = BigInt(randomString)

  const decreasingFactor = currentBlockNum > initialBlockNum ? currentBlockNum - initialBlockNum : 1;

  const difficulty =
    Math.floor(Math.sqrt(amount / amtDifficulty + 1)) +
    Math.floor(Math.sqrt(decreasingFactor / blockDifficulty)) +
    Math.floor(Math.sqrt(totalSupply / totalSupplyDifficulty));

  const result = random % BigInt(difficulty);
  return result === 0n;
}

async function mineAndInscribe() {
  // 挖矿数量范围
  const startAmount = 10;
  const endAmount = 1;

  // Gas settings
  const dynamicGas = true;
  // 如果dynamicGas为true，gasLimit将被忽略
  // 如果dynamicGas为false，你需要手动设置gasLimit
  const gasLimit = 200000;

  const balance = await wallet.provider.getBalance(wallet.address);
  console.log(`============开始尝试挖矿============`);
  console.log(`当前钱包地址: ${wallet.address}`);
  console.log(`当前钱包余额: ${ethers.formatEther(balance)} ETH`);

  const initialBlockNum = await contract.initialBlockNum().then((res) => Number(res));
  console.log(`初始区块高度: ${initialBlockNum}`);

  console.log(`挖矿数量范围: ${startAmount} - ${endAmount}`);

  const currentBlockNum = await provider.getBlockNumber();
  console.log(`当前区块高度: ${currentBlockNum}`);

  const totalSupply = await contract.totalSupply().then((res) => Number(res));
  console.log(`当前总供应量: ${totalSupply}`);

  const promises = [];

  for (let amount = startAmount; amount >= endAmount; amount--) {
    /*
    // 并发任务
    promises.push(
      (async () => {
        try {
          // 链下计算
          const isMinted = await mintingAlgo(amount, initialBlockNum, currentBlockNum, totalSupply);
          // 链上计算
          // const isMinted = await contract.mintingAlgo(lastBlock + 1, amount);

          if (isMinted) {
            console.log(`成功猜出挖矿数量: ${amount}`);

            const inscribeTx = dynamicGas
              ? await contract.inscribe(amount, { gasLimit })
              : await contract.inscribe(amount);

            console.log(`已发送发送挖矿交易，数量: ${amount}`);
            const inscribeResp = await inscribeTx.wait();

            if (inscribeResp.status !== 1) {
              console.log(`挖矿交易失败👀，数量: ${amount}`);
            } else {
              console.log(`恭喜挖矿成功🎉，数量: ${amount}`);
              // 如果有成功的挖矿交易，取消剩余的并发任务
              promises.forEach((p) => p.cancel && p.cancel());
              return;
            }
          } else {
            console.log(`尝试挖矿失败，数量: ${amount}`);
          }
        } catch (error) {
          console.error('Error calling mintingAlgo:', error);
        }
      })()
    );
  }
  // 执行所有并发任务
  await Promise.all(promises);
  */
    try {
      // 链下计算
      const isMinted = await mintingAlgo(amount, initialBlockNum, currentBlockNum, totalSupply);
      // 链上计算
      // const isMinted = await contract.mintingAlgo(lastBlock + 1, amount);

      if (isMinted) {
        console.log(`成功猜出挖矿数量: ${amount}`);

        const inscribeTx = dynamicGas
          ? await contract.inscribe(amount, { gasLimit })
          : await contract.inscribe(amount);

        console.log(`已发送发送挖矿交易，数量: ${amount}`);
        const inscribeResp = await inscribeTx.wait();

        if (inscribeResp.status !== 1) {
          console.log(`挖矿交易失败👀，数量: ${amount}`);
        } else {
          console.log(`恭喜挖矿成功🎉，数量: ${amount}`);
        }
        return;
      } else {
        console.log(`尝试挖矿失败，数量: ${amount}`);
      }
    } catch (error) {
      console.error('Error calling mintingAlgo:', error);
      return;
    }
  }
}

// 持续挖矿
(async () => {
  while (true) {
    await mineAndInscribe();
  }
})();

// mineAndInscribe();