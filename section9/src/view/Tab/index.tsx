import React from 'react';
import {NavLink} from 'react-router-dom';
import './index.less';

const Tab = () => {
    return (
        <div className='tab-root'>
            <div className='tab-wrap'>
                <NavLink 
                    className={({ isActive } : { isActive : boolean }) => (isActive ? 'selected' : '')}  
                    to='txQuery'>TransactionQuery</NavLink>
                <NavLink 
                    className={({ isActive } : { isActive : boolean }) => (isActive ? 'selected' : '')}  
                    to='nftScan'>NFTScanner</NavLink>
                <NavLink 
                    className={({ isActive } : { isActive : boolean }) => (isActive ? 'selected' : '')}  
                    to='wallet'>Wallet</NavLink>
            </div>
        </div>
    );
};

export default Tab;
