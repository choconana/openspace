import React, { useState } from 'react';
import {observer} from 'mobx-react-lite';
import {blockChainStore} from '../../store';
import "./index.less";


const TxQuery = () => {

    const { blockChain } = blockChainStore;
    const { blockInfo, txLog, watchBlock, watchTx, unWatchBlockAction, unWatchTxAction, getStorage } = blockChain;
    
    const [tokenId, setTokenId] = useState('');

    const onWatchTx = () => {
      watchTx(tokenId);
    }

    const changeWatchTx = (e) => {
      setTokenId(e.target.value);
    }

    return (
      <div>
        <div>
          <span>
            <button onClick={watchBlock}>监听Block</button>
            <button onClick={unWatchBlockAction}>关闭区块监听</button>
          </span>
        </div>
        <div>
          <span>
              <i className='left-aligned'>区块高度：</i><i>{ blockInfo.blockNumber }</i>
          </span>
        </div>
        <div>
          <span>
              <i className='left-aligned'>区块hash：</i><i>{ blockInfo.blockHash }</i>
          </span>
        </div>
        <span className='left-aligned'>-------------------------------</span>
        <br/>
        <div>
          <span>
            <input placeholder="请输入tokenId" onChange={changeWatchTx}/>
            <button onClick={onWatchTx}>监听交易</button>
          </span>
          <span>
            <button onClick={unWatchTxAction}>关闭交易监听</button>
          </span>
        </div>
        <div>
          <span>
            <h5>交易信息: </h5>
            <i className='left-aligned'>{txLog}</i>
          </span>
        </div>
      </div>
    );
}

export default observer(TxQuery);