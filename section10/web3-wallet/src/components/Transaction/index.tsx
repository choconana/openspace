import React, { useState } from 'react';
import { publicClient } from '../EtherClient';
import { Block } from 'viem';

interface BlockInfo {
  baseFeePerGas: BigInt
}

const Transaction = () => {

  const [blockNumber, setBlockNumber] = useState('');
  const [searchBn, setSearchBn] = useState<BigInt>();
  const [blockInfo, setBlockInfo] = useState<BlockInfo>()
  async function getBlockNumber() {
    const bn = await publicClient.getBlockNumber();
    setBlockNumber(bn.toString());
  }

  async function getBlock(bn) {
    const block = await publicClient.getBlock({
      blockNumber: bn
    })
    let info;
    if (block.baseFeePerGas != null) {
      info.baseFeePerGas = block.baseFeePerGas
    }
    setBlockInfo(info)
  }
  

  function searchBlock (param:string) {
    setSearchBn(BigInt(param))
  }

  
  return (
    <>
      <div>
        <button onClick={getBlockNumber}>获取区块数量</button>
        <span>
          <i>当前区块数：</i>
          <i>{blockNumber}</i>
        </span>
      </div>
      <div>
        <input placeholder='输入区块id' onChange={() => searchBlock}/>
        <button onClick={() => getBlock(searchBn)}>获取区块</button>
        <span>
          <i>当前区块信息：</i>
          <i>{blockInfo.baseFeePerGas.toString()}</i>
        </span>
      </div>
    </>
  );
};

export default Transaction;
