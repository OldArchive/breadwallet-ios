//
//  AccountHeaderView.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit
import Geth

private let largeFontSize: CGFloat = 26.0
private let smallFontSize: CGFloat = 13.0
private let logoWidth: CGFloat = 0.22 //percentage of width

class AccountHeaderView : UIView, GradientDrawable, Subscriber {

    //MARK: - Public
    init(store: Store) {
        self.store = store
        self.isBtcSwapped = store.state.isBtcSwapped
        if let rate = store.state.currentRate {
            self.exchangeRate = rate
            let placeholderAmount = Amount(amount: 0, rate: rate, maxDigits: store.state.maxDigits, store: store)
            self.secondaryBalance = UpdatingLabel(formatter: placeholderAmount.localFormat)
            self.primaryBalance = UpdatingLabel(formatter: placeholderAmount.btcFormat)
        } else {
            self.secondaryBalance = UpdatingLabel(formatter: NumberFormatter())
            self.primaryBalance = UpdatingLabel(formatter: NumberFormatter())
        }
        super.init(frame: CGRect())
    }

    let search = UIButton(type: .system)

    //MARK: - Private
    private let name = UILabel(font: UIFont.boldSystemFont(ofSize: 17.0))
    private let currencySwitch = UIButton(type: .system)
    private let primaryBalance: UpdatingLabel
    private let secondaryBalance: UpdatingLabel
    private let currencyTapView = UIView()
    private let store: Store
    private let equals = UILabel(font: .customBody(size: smallFontSize), color: .whiteTint)
    private var regularConstraints: [NSLayoutConstraint] = []
    private var swappedConstraints: [NSLayoutConstraint] = []
    private var hasInitialized = false
    private let modeLabel: UILabel = {
        let label = UILabel()
        label.font = .customBody(size: 12.0)
        return label
    }()
    var hasSetup = false

    var isWatchOnly: Bool = false {
        didSet {
            if E.isTestnet || isWatchOnly {
                if E.isTestnet && isWatchOnly {
                    modeLabel.text = "(Testnet - Watch Only)"
                } else if E.isTestnet {
                    modeLabel.text = "(Testnet)"
                } else if isWatchOnly {
                    modeLabel.text = "(Watch Only)"
                }
                modeLabel.isHidden = false
            }
            if E.isScreenshots {
                modeLabel.isHidden = true
            }
        }
    }
    private var exchangeRate: Rate? {
        didSet { setBalances() }
    }
    private var logo: UIImageView = {
        let image = UIImageView(image: #imageLiteral(resourceName: "Logo"))
        image.contentMode = .scaleAspectFit
        return image
    }()
    private var balance: UInt64 = 0 {
        didSet { setBalances() }
    }
    private var bigBalance: GethBigInt? {
        didSet { setEthBalance() }
    }
    private var isBtcSwapped: Bool {
        didSet { setBalances() }
    }

    override func layoutSubviews() {
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        setData()
        addSubviews()
        addConstraints()
        addShadow()
        addSubscriptions()
    }

    private func setData() {
        name.textColor = .white

        currencySwitch.setTitle(S.AccountHeader.switchCurrency, for: .normal)
        currencySwitch.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        currencySwitch.tintColor = .white
        currencySwitch.tap = strongify(self) { myself in
            myself.store.perform(action: RootModalActions.Present(modal: .manageWallet))
        }
        primaryBalance.textColor = .whiteTint
        primaryBalance.font = UIFont.customBody(size: largeFontSize)

        secondaryBalance.textColor = .whiteTint
        secondaryBalance.font = UIFont.customBody(size: largeFontSize)

        search.setImage(#imageLiteral(resourceName: "SearchIcon"), for: .normal)
        search.tintColor = .white

        if E.isTestnet {
            name.textColor = .red
        }

        equals.text = S.AccountHeader.equals

        name.isHidden = true
        modeLabel.isHidden = true
    }

    private func addSubviews() {
        addSubview(name)
        addSubview(currencySwitch)
        addSubview(primaryBalance)
        addSubview(secondaryBalance)
        addSubview(search)
        addSubview(currencyTapView)
        addSubview(equals)
        addSubview(logo)
        addSubview(modeLabel)
    }

    private func addConstraints() {
        name.constrain([
            name.constraint(.leading, toView: self, constant: C.padding[2]),
            name.constraint(.top, toView: self, constant: 30.0) ])
        if let manageTitleLabel = currencySwitch.titleLabel {
            currencySwitch.constrain([
                currencySwitch.constraint(.trailing, toView: self, constant: -C.padding[2]),
                manageTitleLabel.firstBaselineAnchor.constraint(equalTo: name.firstBaselineAnchor) ])
        }
        secondaryBalance.constrain([
            secondaryBalance.constraint(.firstBaseline, toView: primaryBalance, constant: 0.0) ])

        equals.translatesAutoresizingMaskIntoConstraints = false
        primaryBalance.translatesAutoresizingMaskIntoConstraints = false

        regularConstraints = [
            primaryBalance.firstBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[4]),
            primaryBalance.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            equals.firstBaselineAnchor.constraint(equalTo: primaryBalance.firstBaselineAnchor),
            equals.leadingAnchor.constraint(equalTo: primaryBalance.trailingAnchor, constant: C.padding[1]/2.0),
            secondaryBalance.leadingAnchor.constraint(equalTo: equals.trailingAnchor, constant: C.padding[1]/2.0)
        ]

        swappedConstraints = [
            secondaryBalance.firstBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[4]),
            secondaryBalance.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            equals.firstBaselineAnchor.constraint(equalTo: secondaryBalance.firstBaselineAnchor),
            equals.leadingAnchor.constraint(equalTo: secondaryBalance.trailingAnchor, constant: C.padding[1]/2.0),
            primaryBalance.leadingAnchor.constraint(equalTo: equals.trailingAnchor, constant: C.padding[1]/2.0)
        ]

        NSLayoutConstraint.activate(isBtcSwapped ? self.swappedConstraints : self.regularConstraints)

        search.constrain([
            search.constraint(.trailing, toView: self, constant: -C.padding[2]),
            search.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[4]),
            search.constraint(.width, constant: 44.0),
            search.constraint(.height, constant: 44.0) ])
        search.imageEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)

        currencyTapView.constrain([
            currencyTapView.leadingAnchor.constraint(equalTo: name.leadingAnchor, constant: -C.padding[1]),
            currencyTapView.trailingAnchor.constraint(equalTo: currencySwitch.leadingAnchor, constant: C.padding[1]),
            currencyTapView.topAnchor.constraint(equalTo: primaryBalance.topAnchor, constant: -C.padding[1]),
            currencyTapView.bottomAnchor.constraint(equalTo: primaryBalance.bottomAnchor, constant: C.padding[1]) ])

        let gr = UITapGestureRecognizer(target: self, action: #selector(currencySwitchTapped))
        if !store.isEthLike { //FIXME - currency switching disabled for ethereum
            currencyTapView.addGestureRecognizer(gr)
        }

        logo.constrain([
            logo.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            logo.topAnchor.constraint(equalTo: topAnchor, constant: 30.0),
            logo.heightAnchor.constraint(equalTo: logo.widthAnchor, multiplier: C.Sizes.logoAspectRatio),
            logo.widthAnchor.constraint(equalTo: widthAnchor, multiplier: logoWidth) ])
        modeLabel.constrain([
            modeLabel.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: C.padding[1]/2.0),
            modeLabel.firstBaselineAnchor.constraint(equalTo: logo.bottomAnchor, constant: -2.0) ])
        if store.isEthLike {
            setEthBalance()
        }
    }

    private func transform(forView: UIView) ->  CGAffineTransform {
        forView.transform = .identity //Must reset the view's transform before we calculate the next transform
        let scaleFactor: CGFloat = smallFontSize/largeFontSize
        let deltaX = forView.frame.width * (1-scaleFactor)
        let deltaY = forView.frame.height * (1-scaleFactor)
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return scale.translatedBy(x: -deltaX, y: deltaY/2.0)
    }

    private func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 8.0
    }

    private func addSubscriptions() {
        store.lazySubscribe(self,
                        selector: { $0.isBtcSwapped != $1.isBtcSwapped },
                        callback: { self.isBtcSwapped = $0.isBtcSwapped })
        store.lazySubscribe(self,
                        selector: { $0.currentRate != $1.currentRate},
                        callback: {
                            if let rate = $0.currentRate {
                                let placeholderAmount = Amount(amount: 0, rate: rate, maxDigits: $0.maxDigits, store: self.store)
                                self.secondaryBalance.formatter = placeholderAmount.localFormat
                                self.primaryBalance.formatter = placeholderAmount.btcFormat
                            }
                            self.exchangeRate = $0.currentRate
                        })
        
        store.lazySubscribe(self,
                        selector: { $0.maxDigits != $1.maxDigits},
                        callback: {
                            if let rate = $0.currentRate {
                                let placeholderAmount = Amount(amount: 0, rate: rate, maxDigits: $0.maxDigits, store: self.store)
                                self.secondaryBalance.formatter = placeholderAmount.localFormat
                                self.primaryBalance.formatter = placeholderAmount.btcFormat
                                self.setBalances()
                            }
        })
        store.subscribe(self,
                        selector: { $0.walletState.name != $1.walletState.name },
                        callback: { self.name.text = $0.walletState.name })
        if store.isEthLike {
            store.subscribe(self,
                            selector: { $0.walletState.bigBalance != $1.walletState.bigBalance },
                            callback: { state in
                                if let bigBalance = state.walletState.bigBalance {
                                    self.bigBalance = bigBalance
                                } })
        } else {
            store.subscribe(self,
                            selector: {$0.walletState.balance != $1.walletState.balance },
                            callback: { state in
                                if let balance = state.walletState.balance {
                                    self.balance = balance
                                } })
        }
    }

    private func setEthBalance() {
        guard let bigBalance = bigBalance else { return }
        if store.state.currency == .ethereum {
            primaryBalance.text = DisplayAmount.ethString(value: bigBalance, store: store)
            secondaryBalance.text = DisplayAmount.localEthString(value: bigBalance, store: store)
            DispatchQueue.main.async {
                self.secondaryBalance.transform = self.transform(forView: self.secondaryBalance) //this needs to be in the next run-loop for some reason
            }
        } else {
            guard let token = store.state.walletState.token else { return }
            primaryBalance.text = "\(token.symbol)" + bigBalance.getString(10)
            secondaryBalance.text = ""
            secondaryBalance.transform = transform(forView: secondaryBalance)
            equals.text = ""
        }
    }

    private func setBalances() {
        guard let rate = exchangeRate else { return }
        let amount = Amount(amount: balance, rate: rate, maxDigits: store.state.maxDigits, store: store)
        if !hasInitialized {
            let amount = Amount(amount: balance, rate: exchangeRate!, maxDigits: store.state.maxDigits, store: store)
            NSLayoutConstraint.deactivate(isBtcSwapped ? regularConstraints : swappedConstraints)
            NSLayoutConstraint.activate(isBtcSwapped ? swappedConstraints : regularConstraints)
            primaryBalance.setValue(amount.amountForBtcFormat)
            secondaryBalance.setValue(amount.localAmount)
            if isBtcSwapped {
                primaryBalance.transform = transform(forView: primaryBalance)
            } else {
                secondaryBalance.transform = transform(forView: secondaryBalance)
            }
            hasInitialized = true
            hideExtraViews()
        } else {
            if primaryBalance.isHidden {
                primaryBalance.isHidden = false
            }

            if secondaryBalance.isHidden {
                secondaryBalance.isHidden = false
            }

            primaryBalance.setValueAnimated(amount.amountForBtcFormat, completion: { [weak self] in
                guard let myself = self else { return }
                if !myself.isBtcSwapped {
                    myself.primaryBalance.transform = .identity
                } else {
                    myself.primaryBalance.transform = myself.transform(forView: myself.primaryBalance)
                }
                myself.hideExtraViews()
            })
            secondaryBalance.setValueAnimated(amount.localAmount, completion: { [weak self] in
                guard let myself = self else { return }
                if myself.isBtcSwapped {
                    myself.secondaryBalance.transform = .identity
                } else {
                    myself.secondaryBalance.transform = myself.transform(forView: myself.secondaryBalance)
                }
                myself.hideExtraViews()
            })
        }
    }

    private func hideExtraViews() {
        //TODO - fix
        if store.isEthLike { return }
        var didHide = false
        if secondaryBalance.frame.maxX > search.frame.minX {
            secondaryBalance.isHidden = true
            didHide = true
        } else {
            secondaryBalance.isHidden = false
        }

        if primaryBalance.frame.maxX > search.frame.minX {
            primaryBalance.isHidden = true
            didHide = true
        } else {
            primaryBalance.isHidden = false
        }
        equals.isHidden = didHide
    }

    override func draw(_ rect: CGRect) {
        if store.state.currency == .bitcoin {
            drawGradient(rect)
        } else {
            drawGradient(start: store.state.currency.gradientColours.0,
                            end: store.state.currency.gradientColours.1,
                            rect)
        }
    }

    @objc private func currencySwitchTapped() {
        layoutIfNeeded()
        UIView.spring(0.7, animations: {
            self.primaryBalance.transform = self.primaryBalance.transform.isIdentity ? self.transform(forView: self.primaryBalance) : .identity
            self.secondaryBalance.transform = self.secondaryBalance.transform.isIdentity ? self.transform(forView: self.secondaryBalance) : .identity
            NSLayoutConstraint.deactivate(!self.isBtcSwapped ? self.regularConstraints : self.swappedConstraints)
            NSLayoutConstraint.activate(!self.isBtcSwapped ? self.swappedConstraints : self.regularConstraints)
            self.layoutIfNeeded()
        }) { _ in }

        self.store.perform(action: CurrencyChange.toggle())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
