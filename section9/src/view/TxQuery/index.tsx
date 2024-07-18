import React from 'react';
import {observer} from 'mobx-react-lite';
import {Button, Flex, Input} from 'antd';
import {blockChainStore} from '@/store';
import "./index.less";

const { Search } = Input;

const TxQuery = () => {

    const { blockChain } = blockChainStore;
    const { blockInfo, txLog, watchBlock, watchTx, unWatchBlockAction, unWatchTxAction } = blockChain;
    
    
    return (
        <Flex className='tx-query' vertical>
            <tr>
                <th>
                    <Button type="primary" onClick={watchBlock}>监听Block</Button>
                </th>
                <th>
                    <Button type="primary" onClick={unWatchBlockAction}>关闭区块监听</Button>
                </th>
                <br/>
                <th>
                    <i className='left-aligned'>区块高度：</i><i>{ blockInfo.blockNumber }</i>
                </th>
                <br/>
                <th>
                    <i className='left-aligned'>区块hash：</i><i>{ blockInfo.blockHash }</i>
                </th>
            </tr>
            <br/>
            <span className='left-aligned'>-------------------------------</span>
            <br/>
            <tr>
                <th>
                    <Search
                        placeholder="请输入tokenId"
                        allowClear
                        enterButton="监听交易"
                        onSearch={(hash)=>watchTx(hash)}
                    />
                </th>
                <br/>
                <th>
                    <Button type="primary" onClick={unWatchTxAction}>关闭交易监听</Button>
                </th>
                <br/>
                <th>
                    <span>交易信息:</span>
                </th>
                <br/>
                <th>
                    <i className='left-aligned'>{txLog}</i>
                </th>
            </tr>
        </Flex>
    );
}

export default observer(TxQuery);