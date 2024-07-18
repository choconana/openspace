import { http, createPublicClient, parseAbiItem } from 'viem'
import { mainnet } from 'viem/chains'

async function main() {
  const publicClient = createPublicClient({
    chain: mainnet,
    transport: http("https://eth-mainnet.g.alchemy.com/v2/ToDOPYbbyBKiCdbWdhYBf6FrS3M23oAk"),
  })
  const latesBlockNumber = await publicClient.getBlockNumber();
  console.log(latesBlockNumber);

  const filter = await publicClient.createEventFilter({
    address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'), 
    fromBlock: latesBlockNumber - 100n,
    toBlock: latesBlockNumber
  })
  const logs = await publicClient.getFilterLogs({ filter })
  for (const log of logs) {
    const { from, to, value } = log.args || {};
    if (from && to && value) {
        console.log(`从 ${from} 转账给 ${to} ${value} USDC, 交易ID：${log.transactionHash}`);
    } else {
        console.log('日志解析错误：', log);
    }
}

}

main();