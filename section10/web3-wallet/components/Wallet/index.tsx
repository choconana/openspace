import React, { ReactNode } from 'react';
import './index.less';
import { createWeb3Modal } from '@web3modal/wagmi/react'
import { defaultWagmiConfig } from '@web3modal/wagmi/react/config'

import { WagmiProvider } from 'wagmi'
import { arbitrum, mainnet } from 'wagmi/chains'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient()

// 1. Get projectId from https://cloud.walletconnect.com
const projectId = '04a801d386dc7fa9f9ef84df2ea3ea35'

// 2. Create wagmiConfig
const metadata = {
  name: 'Web3Modal',
  description: 'Web3Modal Example',
  url: 'http://127.0.0.1:8080', // origin must match your domain & subdomain
  icons: ['https://avatars.githubusercontent.com/u/37784886']
}

const chains = [mainnet, arbitrum] as const
const config = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
})

// 3. Create modal
createWeb3Modal({
  wagmiConfig: config,
  projectId,
  enableAnalytics: true, // Optional - defaults to your Cloud configuration
  enableOnramp: true // Optional - false as default
})

function Web3ModalProvider({ children }: { children: ReactNode}) {
    return (
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      </WagmiProvider>
    )
}
const Web3Connect = function ConnectButton() {
    return (
        <div className='web3-wallet'>
          {/* <span>Web3 Wallet</span> */}
            <Web3ModalProvider>
                <w3m-button />
            </Web3ModalProvider>
        </div>
    );
}
export default Web3Connect;