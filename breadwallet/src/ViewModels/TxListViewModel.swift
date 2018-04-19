//
//  TxListViewModel.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-13.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

/// View model of a transaction in list view
struct TxListViewModel: TxViewModel {
    
    // MARK: - Properties
    
    let tx: Transaction
    
    var shortDescription: String {
        let isComplete = tx.status == .complete
        
        if let comment = comment, comment.count > 0, isComplete {
            return comment
        } else if let tokenCode = tokenTransferCode {
            return String(format: S.Transaction.tokenTransfer, tokenCode.uppercased())
        } else {
            var address = tx.toAddress
            var format: String
            switch tx.direction {
            case .sent, .moved:
                format = isComplete ? S.Transaction.sentTo : S.Transaction.sendingTo
            case .received:
                if let tx = tx as? EthLikeTransaction {
                    format = isComplete ? S.Transaction.receivedFrom : S.Transaction.receivingFrom
                    address = tx.fromAddress
                } else {
                    format = isComplete ? S.Transaction.receivedVia : S.Transaction.receivingVia
                }
            }
            if currency.matches(Currencies.bch) {
                address = address.replacingOccurrences(of: "\(Currencies.bch.urlScheme!):", with: "")
            }
            return String(format: format, address)
        }
    }

    func amount(isBtcSwapped: Bool, rate: Rate) -> NSAttributedString {
        let text = Amount(amount: tx.amount,
                          currency: tx.currency,
                          rate: isBtcSwapped ? rate : nil,
                          negative: (tx.direction == .sent)).description
        let color: UIColor = (tx.direction == .received) ? .receivedGreen : .darkGray
        
        return NSMutableAttributedString(string: text,
                                         attributes: [.foregroundColor: color])
    }
}
