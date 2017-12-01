//
//  EthTx.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-10-24.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation
import Geth

struct EthTxList : Codable {
    let status: String
    let message: String
    let result: [EthTx]
}

struct EthTx : Codable {
    let blockNumber: String
    let timeStamp: String
    let value: String
    let from: String
    let to: String
    let confirmations: String
    let hash: String
}

struct TokenBalance : Codable {
    let status: String
    let message: String
    let result: String
}

struct Token {
    let name: String
    let code: String
    let symbol: String
    let address: String
    let decimals: Int
    let abi: String
}

struct Crowdsale {
    let startTime: Date?
    let endTime: Date?
    let contract = Contract(address: "0x4B0B6b8E05dCF1D1bFD3C19e2ea8707b35D03cD7", abi: crowdSaleABI)
}

struct Contract {
    let address: String
    let abi: String
}

struct EventResponse : Codable {
    let status: String
    let message: String
    let result: [Event]
}

struct Event : Codable {
    let address: String
    let topics: [String]
    let data: String
    let timeStamp: String
    let transactionHash: String
    var isComplete = true

    private enum CodingKeys: String, CodingKey {
        case address
        case topics
        case data
        case timeStamp
        case transactionHash
    }
}

extension Event {
    init(timestamp: String, from: String, to: String, amount: String) {
        let topics = ["",from,to]
        let timestampNumber = GethBigInt(0)
        timestampNumber?.setString(timestamp, base: 10)

        let amountNumber = GethBigInt(0)
        amountNumber?.setString(amount, base: 10)
        self.init(address: "", topics: topics, data: amountNumber!.getString(16), timeStamp: timestampNumber!.getString(16), transactionHash: "", isComplete: false)
        self.isComplete = false
    }
}

extension Crowdsale : Equatable { }

func == (lhs: Crowdsale, rhs: Crowdsale) -> Bool {
    return lhs.startTime == rhs.startTime && lhs.endTime == rhs.endTime
}

let crowdSaleABI = """
[{"constant":true,"inputs":[],"name":"lockup","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"rate","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"endTime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"cap","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"weiRaised","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finalize","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"wallet","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"startTime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"maxContribution","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"isFinalized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ownerShare","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"minContribution","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"authorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"lockupTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"beneficiary","type":"address"}],"name":"buyTokens","outputs":[],"payable":true,"type":"function"},{"constant":true,"inputs":[],"name":"hasEnded","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"unlockTokens","outputs":[{"name":"_didIssueRewards","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_cap","type":"uint256"},{"name":"_minWei","type":"uint256"},{"name":"_maxWei","type":"uint256"},{"name":"_startTime","type":"uint256"},{"name":"_endTime","type":"uint256"},{"name":"_rate","type":"uint256"},{"name":"_ownerShare","type":"uint256"},{"name":"_wallet","type":"address"},{"name":"_authorizer","type":"address"},{"name":"_numUnlockIntervals","type":"uint256"},{"name":"_unlockIntervalDuration","type":"uint256"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[],"name":"Finalized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"previousOwner","type":"address"},{"indexed":true,"name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"purchaser","type":"address"},{"indexed":true,"name":"beneficiary","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"TokenPurchase","type":"event"}]
"""