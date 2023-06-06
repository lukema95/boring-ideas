# 概述
nft-scaffold 是一个NFT项目开发模版，使用hardhat框架来在本地进行合约的执行和测试。使用Next.js来启动网页，
网页包含NFT Mint的功能。

# 快速开始
## Hardhat启动
在终端输入以下命令，启动Hardhat本地节点
```shell
npx hardhat node

```

打开另一个终端，测试并部署合约
```shell
# 执行合约的单元测试脚本
npx hardhat test

# 部署合约到本地Hardhat节点
npx hardhat run scripts/deploy.ts --network localhost
```

## 启动Next服务
```shell
npm install
npm run build
npm run start
```
