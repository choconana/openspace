import useSWR from 'swr';
import Web3Connect from '../components/Wallet';
import Transaction from '../components/Transaction';

const fetcher = (url: string) => fetch(url).then((res) => res.json());

export default function Index() {

  return (
    <>
      <Web3Connect />
      <br/>
      <span>-------------------------------</span>
      <br/>
      <Transaction />
    </>
  );
}
