import React from 'react';
import {observer} from 'mobx-react-lite';
import './index.less';
import {Flex, Input} from 'antd';
import {blockChainStore} from '@/store';

const { Search } = Input;

const NftScan = () => {

    const { blockChain } = blockChainStore;
    const { owner, tokenURI, getOwner, getTokenURI } = blockChain;
    
    
    return (
        <Flex className='nft-scanner' vertical>
            {/* <span>Welcome To The NFT Scanner</span> */}
            <tr>
                <th>
                    <Search
                        placeholder="请输入tokenId"
                        allowClear
                        enterButton="查询Owner"
                        onSearch={(tokenId)=>getOwner(tokenId)}
                    />
                </th>
            </tr>
            <tr>
                <th>
                    <span>owner: </span><i>{ owner }</i>
                </th>
            </tr>
            <tr>
            </tr>
            <tr>
                <th>
                    <Search
                        placeholder="请输入tokenId"
                        allowClear
                        enterButton="查询tokenURI"
                        onSearch={(tokenId)=>getTokenURI(tokenId)}
                    />
                </th>
            </tr>
            <br />
            <tr>
                <th>
                    <span>tokenURI: </span><i>{ tokenURI }</i>
                </th>
            </tr>
        </Flex>
    );
}

export default observer(NftScan);