/*
 * react-router-dom v6 官方文档
 * https://reactrouter.com/en/v6.3.0/getting-started/installation
 */
import React from 'react';
import SuspenseLazy from '@/components/SuspenseLazy';
import {Navigate, RouteObject} from 'react-router-dom';

const NotFound = SuspenseLazy(() => import(/* webpackChunkName:"not-found" */ '@/view/NotFound'));
const NftScan = SuspenseLazy(() => import(/* webpackChunkName:"dashboard" */ '@/view/NftScan'));
const Wallet = SuspenseLazy(() => import(/* webpackChunkName:"dashboard" */ '@/view/Wallet'));
const TxQuery = SuspenseLazy(() => import(/* webpackChunkName:"dashboard" */ '@/view/TxQuery'));


const routes: RouteObject[] = [
    {
        path: '/',
        element: <Navigate to='txQuery' /> // 重定向
    },
    {
        path: 'txQuery',
        element: TxQuery
    },
    {
        path: 'nftScan',
        element: NftScan
    },
    {
        path: 'wallet',
        element: Wallet
    },
    // 未匹配到页面
    {
        path: '*',
        element: NotFound
    }
];

export default routes;
