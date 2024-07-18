import {makeAutoObservable, runInAction} from 'mobx';
import { client } from '../etherclient';
import { parseAbiItem } from 'viem';


class BlockChain {
    constructor() {
        // makeAutoObservable: 自动将所有属性和方法转换为可观察对象。
        makeAutoObservable(this);
    }
    loading = true;

    blockNum = '0';
    owner = '';
    tokenURI = '';

    blockInfo = {
        blockNumber: '',
        blockHash: ''
    };

    txLog = '';

    unwatchBlock = () => {};
    unwatchTx = () => {};

    abi = [
        {
            inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
            name: "ownerOf",
            outputs: [{ internalType: "address", name: "", type: "address" }],
            stateMutability: "view",
            type: "function",
        },
        {
            inputs: [{ internalType: "uint256", name: "_tokenId", type: "uint256" }],
            name: "tokenURI",
            outputs: [{ internalType: "string", name: "", type: "string" }],
            stateMutability: "view",
            type: "function",
        },
    ]

    getBlockNumber = async () => {
        runInAction(() => {
            this.loading = true;
        });
        this.blockNum = String(await client.getBlockNumber()) 
    }

    getOwner = async (param:string) => {
        const data = await client.readContract({
            address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
            abi: this.abi,
            functionName: 'ownerOf',
            args: [param]
        })
        this.owner = data as string;
    }

    getFilter = async () => {

    }

    getTokenURI = async (param:string) => {
        const data = await client.readContract({
            address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
            abi: this.abi,
            functionName: 'tokenURI',
            args: [param]
        })
        this.tokenURI = data as string;
    }

    watchBlock = async () => {
        this.unwatchBlock = client.watchBlocks({ 
                onBlock: block => {
                    if(block) {
                        this.blockInfo.blockNumber = block.number.toString();
                        this.blockInfo.blockHash = block.hash;
                    }
                },
                pollingInterval: 1_000, 
            }
        )
    }

    watchTx = async (param:string) => {
        const unwatch = client.watchEvent({
            address: param as `0x${string}`,
            event: parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)'), 
            onLogs: logs => {
                if (logs && logs.length > 0) {
                    const { blockNumber, blockHash, topics, data } = logs[logs.length - 1];
                    const amount = parseInt(data) / 10e6;
                    this.txLog = `在 ${blockNumber} 区块 ${blockHash} 交易中从 ${topics[1]} 转账 ${amount} USDT 到 ${topics[2]}`;
                }
            }
        })
        this.unwatchTx = unwatch
        console.log(this.unwatchTx)
        
    }

    unWatchBlockAction = () => {
        this.unwatchBlock.call(this.unwatchBlock);
        this.blockInfo = { blockHash: '',  blockNumber: ''};
    }

    unWatchTxAction = () => {
        this.unwatchTx.call(this.unwatchTx);
        this.txLog = '';
    }
    
}

const blockChain = new BlockChain();
export {blockChain};