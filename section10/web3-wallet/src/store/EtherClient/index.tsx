import { createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';

export const client = createPublicClient({
  chain: mainnet,
  transport: http("https://eth-mainnet.g.alchemy.com/v2/ToDOPYbbyBKiCdbWdhYBf6FrS3M23oAk"),
})
