import {makeAutoObservable, runInAction} from 'mobx';
import { createPublicClient, http, stringify } from 'viem';
import { mainnet } from 'viem/chains';


class BlockChain {
    constructor() {
        // makeAutoObservable: 自动将所有属性和方法转换为可观察对象。
        makeAutoObservable(this);
    }
    loading = true;

    blockNum = '0';
    owner = '';
    tokenURI = '';
    
    client = createPublicClient({
        chain: mainnet,
        transport: http(),
    })

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
        this.blockNum = stringify(await this.client.getBlockNumber()) 
    }

    getOwner = async (param:string) => {
        debugger
        const data = await this.client.readContract({
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
        debugger
        const data = await this.client.readContract({
            address: '0x0483b0dfc6c78062b9e999a82ffb795925381415',
            abi: this.abi,
            functionName: 'tokenURI',
            args: [param]
        })
        this.tokenURI = data as string;
    }
}

const blockChain = new BlockChain();
export {blockChain};