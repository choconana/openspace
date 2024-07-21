import {
  Buy as BuyEvent,
  ForSale as ForSaleEvent
} from "../generated/NFTMarket/NFTMarket"
import { Buy, ForSale } from "../generated/schema"

export function handleBuy(event: BuyEvent): void {
  let entity = new Buy(event.transaction.hash.concatI32(event.logIndex.toI32()))
  entity.buyer = event.params.buyer
  entity.tokenId = event.params.tokenId
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleForSale(event: ForSaleEvent): void {
  let entity = new ForSale(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.seller = event.params.seller
  entity.tokenId = event.params.tokenId
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
