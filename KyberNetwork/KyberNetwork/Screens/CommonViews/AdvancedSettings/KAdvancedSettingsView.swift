// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Crashlytics

enum KNSelectedGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case superFast = 3
  case custom
}

enum KAdvancedSettingsViewEvent {
  case infoPressed
  case displayButtonPressed
  case gasPriceChanged(type: KNSelectedGasPriceType, value: BigInt)
  case minRatePercentageChanged(percent: CGFloat)
}

enum KAdvancedSettingsMinRateType {
  case threePercent
  case anyRate
  case custom(value: Double)
}

protocol KAdvancedSettingsViewDelegate: class {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent)
}

class KAdvancedSettingsViewModel: NSObject {

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()

  private let kGasPriceContainerHeight: CGFloat = 80.0
  private let kMinRateContainerHeight: CGFloat = 140.0
  private let kAdvancedSettingsHasMinRateHeight: CGFloat = 310.0
  private let kAdvancedSettingsNoMinRateHeight: CGFloat = 168.0

  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var superFast: BigInt = KNGasCoordinator.shared.superFastKNGas

  fileprivate(set) var selectedType: KNSelectedGasPriceType = .medium

  fileprivate(set) var isViewHidden: Bool = true
  fileprivate(set) var hasMinRate: Bool = true

  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .threePercent
  fileprivate(set) var currentRate: Double = 0.0

  fileprivate(set) var pairToken: String = ""
  fileprivate(set) var isPromoWallet: Bool = false

  init(hasMinRate: Bool, isPromo: Bool) {
    self.hasMinRate = hasMinRate
    self.isPromoWallet = isPromo
  }

  var advancedSettingsHeight: CGFloat {
    if self.isViewHidden { return 0.0 }
    return self.hasMinRate ? kAdvancedSettingsHasMinRateHeight : kAdvancedSettingsNoMinRateHeight
  }

  var isGasPriceViewHidden: Bool { return self.isViewHidden }
  var gasPriceViewHeight: CGFloat { return self.isGasPriceViewHidden ? 0 : kGasPriceContainerHeight }

  var fastGasString: NSAttributedString {
    return self.attributedString(
      for: self.fast,
      text: NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    )
  }
  var mediumGasString: NSAttributedString {
    return self.attributedString(
      for: self.medium,
      text: NSLocalizedString("regular", value: "Regular", comment: "").uppercased()
    )
  }
  var slowGasString: NSAttributedString {
    return self.attributedString(
      for: self.slow,
      text: NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
    )
  }
  var superFastGasString: NSAttributedString {
    return self.attributedString(
      for: self.superFast,
      text: NSLocalizedString("super.fast", value: "Super Fast", comment: "").uppercased()
    )
  }
  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: "\n\(text)", attributes: feeAttributes))
    return attributedString
  }

  var isMinRateViewHidden: Bool { return !self.hasMinRate || self.isViewHidden }
  var minRateViewHeight: CGFloat { return self.isMinRateViewHidden ? 0 : kMinRateContainerHeight }
  var minRateTypeInt: Int {
    switch self.minRateType {
    case .threePercent: return 0
    case .anyRate: return 1
    case .custom: return 2
    }
  }

  var minRatePercent: Double {
    switch self.minRateType {
    case .threePercent: return 3.0
    case .anyRate: return 100.0
    case .custom(let value): return value
    }
  }

  var minRateDisplay: String {
    let minRate = self.currentRate * (100.0 - self.minRatePercent) / 100.0
    return self.numberFormatter.string(from: NSNumber(value: minRate))?.displayRate() ?? "0"
  }

  var currentRateDisplay: String {
    return self.numberFormatter.string(from: NSNumber(value: self.currentRate))?.displayRate() ?? "0"
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    if self.isPromoWallet {
      let extraGas = KNGasConfiguration.extraGasPromoWallet
      self.fast = fast + extraGas
      self.medium = medium
      self.slow = slow
      self.superFast = superFast
    } else {
      self.fast = fast
      self.medium = medium
      self.slow = slow
      self.superFast = superFast
    }
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func updatePairToken(_ value: String) {
    self.pairToken = value
  }

  func updateViewHidden(isHidden: Bool) { self.isViewHidden = isHidden }

  func updateMinRateType(_ type: KAdvancedSettingsMinRateType) {
    self.minRateType = type
  }

  func updateMinRateValue(_ value: Double, percent: Double) {
    self.currentRate = value
    if self.minRateTypeInt == 2 {
      self.minRateType = .custom(value: percent)
    }
  }

  func updateIsPromoWallet(_ isPromo: Bool) {
    self.isPromoWallet = isPromo
    self.updateSelectedType(.fast)
    self.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
  }

  func updateHasMinRate(hasMinRate: Bool) { self.hasMinRate = hasMinRate }

  var totalHeight: CGFloat {
    return 64.0 + self.advancedSettingsHeight
  }
}

class KAdvancedSettingsView: XibLoaderView {

  @IBOutlet weak var displayViewButton: UIButton!

  @IBOutlet weak var advancedSettingsViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var advancedContainerView: UIView!

  @IBOutlet weak var gasPriceContainerView: UIView!
  @IBOutlet weak var gasFeeGweiTextLabel: UILabel!

  @IBOutlet weak var superFastGasButton: UIButton!
  @IBOutlet weak var superFastGasValueLabel: UILabel!

  @IBOutlet weak var fasGasValueLabel: UILabel!
  @IBOutlet weak var fasGasButton: UIButton!

  @IBOutlet weak var mediumGasValueLabel: UILabel!
  @IBOutlet weak var mediumGasButton: UIButton!

  @IBOutlet weak var slowGasValueLabel: UILabel!
  @IBOutlet weak var slowGasButton: UIButton!

  @IBOutlet weak var minRateContainerView: UIView!

  @IBOutlet weak var threePercentButton: UIButton!
  @IBOutlet weak var customButton: UIButton!

  @IBOutlet weak var threePercentTextLabel: UILabel!
  @IBOutlet weak var customTextLabel: UILabel!
  @IBOutlet weak var customRateTextField: UITextField!
  @IBOutlet weak var stillProceedIfRateGoesDownTextLabel: UILabel!
  @IBOutlet weak var transactionWillBeRevertedTextLabel: UILabel!

  fileprivate var isPromo: Bool = false
  fileprivate(set) var viewModel: KAdvancedSettingsViewModel!
  weak var delegate: KAdvancedSettingsViewDelegate?

  var isMinRateValid: Bool {
    if case .threePercent = self.viewModel.minRateType { return true }
    let custom = self.customRateTextField.text ?? ""
    return !custom.isEmpty
  }

  var height: CGFloat {
    if self.viewModel == nil { return 64.0 }
    return self.viewModel.totalHeight
  }

  var isExpanded: Bool { return !self.viewModel.isViewHidden }

  override func commonInit() {
    super.commonInit()
    self.displayViewButton.setTitle(
      NSLocalizedString("advanced.optional", value: "Advanced (optional)", comment: ""),
      for: .normal
    )
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.customRateTextField.delegate = self
    self.advancedContainerView.rounded(radius: 5.0)
    self.superFastGasButton.backgroundColor = .white
    self.fasGasButton.backgroundColor = .white
    self.mediumGasButton.backgroundColor = .white
    self.slowGasButton.backgroundColor = .white
    self.threePercentButton.backgroundColor = .white
    self.customButton.backgroundColor = .white

    let tapSuperFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSuperFastFee(_:)))
    self.superFastGasValueLabel.addGestureRecognizer(tapSuperFast)

    let tapFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedFastFee(_:)))
    self.fasGasValueLabel.addGestureRecognizer(tapFast)

    let tapMedium = UITapGestureRecognizer(target: self, action: #selector(self.userTappedMediumFee(_:)))
    self.mediumGasValueLabel.addGestureRecognizer(tapMedium)

    let tapSlow = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSlowFee(_:)))
    self.slowGasValueLabel.addGestureRecognizer(tapSlow)

    let tapThreePercent = UITapGestureRecognizer(target: self, action: #selector(self.userTappedThreePercent(_:)))
    self.threePercentTextLabel.addGestureRecognizer(tapThreePercent)

    let tapCustom = UITapGestureRecognizer(target: self, action: #selector(self.userTappedCustomRate(_:)))
    self.customTextLabel.addGestureRecognizer(tapCustom)
  }

  func updateViewModel(_ viewModel: KAdvancedSettingsViewModel) {
    self.viewModel = viewModel
    self.viewModel.updateIsPromoWallet(isPromo)
    self.advancedSettingsViewHeightConstraint.constant = self.viewModel.advancedSettingsHeight
    self.advancedContainerView.isHidden = self.viewModel.isViewHidden
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
  }

  func updateMinRateCustomErrorShown(_ isShown: Bool) {
    let borderColor = isShown ? UIColor.Kyber.strawberry : UIColor.Kyber.border
    self.customRateTextField.rounded(color: borderColor, width: 1.0, radius: 2.5)
  }

  fileprivate func updateGasPriceUIs() {
    if self.viewModel == nil { return }
    self.gasPriceContainerView.isHidden = self.viewModel.isGasPriceViewHidden

    self.superFastGasValueLabel.attributedText = self.viewModel.superFastGasString
    self.fasGasValueLabel.attributedText = self.viewModel.fastGasString
    self.mediumGasValueLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasValueLabel.attributedText = self.viewModel.slowGasString

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasButton.rounded(
      color: self.viewModel.selectedType == .superFast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.fasGasButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.mediumGasButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.mediumGasButton.frame.height / 2.0
    )

    self.slowGasButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasButton.frame.height / 2.0
    )

    self.updateConstraintsIfNeeded()
    self.layoutIfNeeded()
  }

  fileprivate func updateMinRateUIs() {
    if self.viewModel == nil { return }
    self.minRateContainerView.isHidden = self.viewModel.isMinRateViewHidden
    if self.minRateContainerView.isHidden { return }

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.threePercentButton.rounded(
      color: self.viewModel.minRateTypeInt == 0  ? selectedColor : normalColor,
      width: self.viewModel.minRateTypeInt == 0 ? selectedWidth : normalWidth,
      radius: self.threePercentButton.frame.height / 2.0
    )

    self.customButton.rounded(
      color: self.viewModel.minRateTypeInt == 2 ? selectedColor : normalColor,
      width: self.viewModel.minRateTypeInt == 2 ? selectedWidth : normalWidth,
      radius: self.customButton.frame.height / 2.0
    )

    self.customRateTextField.isEnabled = self.viewModel.minRateTypeInt == 2

    self.stillProceedIfRateGoesDownTextLabel.text = String(
      format: NSLocalizedString("still.proceed.if.rate.goes.down.by", value: "Still proceed if %@ goes down by:", comment: ""),
      self.viewModel.pairToken
    )
    self.transactionWillBeRevertedTextLabel.text = String(
      format: NSLocalizedString("transaction.will.be.reverted.if.rate.lower.than", value: "Transaction will be reverted if rate of %@ is lower than %@ (Current rate %@)", comment: ""),
      arguments: [self.viewModel.pairToken, self.viewModel.minRateDisplay, self.viewModel.currentRateDisplay]
    )
    self.updateMinRateCustomErrorShown(!self.isMinRateValid)
    self.updateConstraints()
    self.layoutSubviews()
  }

  func updatePairToken(_ value: String) {
    if self.viewModel == nil { return }
    self.viewModel.updatePairToken(value)
    self.updateGasPriceUIs()
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    if self.viewModel == nil { return }
    self.viewModel.updateGasPrices(fast: fast, medium: medium, slow: slow, superFast: superFast)
    let gasPrice: BigInt = {
      switch self.viewModel.selectedType {
      case .fast: return self.viewModel.fast
      case .medium: return self.viewModel.medium
      case .slow: return self.viewModel.slow
      case .superFast: return self.viewModel.superFast
      default: return BigInt(0)
      }
    }()
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: self.viewModel.selectedType, value: gasPrice))
    self.updateGasPriceUIs()
  }

  func updateHasMinRate(_ hasMinRate: Bool) {
    if self.viewModel == nil { return }
    self.viewModel.updateHasMinRate(hasMinRate: hasMinRate)
    self.updateMinRateUIs()
  }

  func updateMinRate(_ value: Double, percent: Double) {
    if self.viewModel == nil { return }
    self.viewModel.updateMinRateValue(value, percent: percent)
    self.updateMinRateUIs()
  }

  func updateIsPromoWallet(_ isPromo: Bool) {
    self.isPromo = isPromo
    if self.viewModel == nil { return }
    self.viewModel.updateIsPromoWallet(isPromo)
    self.updateGasPriceUIs()
  }

  @IBAction func displayViewButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    let isHidden = !self.viewModel.isViewHidden
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "display_\(isHidden ? "show" : "hide")"])
    self.viewModel.updateViewHidden(isHidden: isHidden)

    self.advancedSettingsViewHeightConstraint.constant = self.viewModel.advancedSettingsHeight
    self.advancedContainerView.isHidden = self.viewModel.isViewHidden

    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .displayButtonPressed)
  }

  @IBAction func superFastGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.superFast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .superFast, value: self.viewModel.superFast))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_super_fast"])
    self.updateGasPriceUIs()
  }

  @IBAction func fastGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast, value: self.viewModel.fast))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_fast"])
    self.updateGasPriceUIs()
  }

  @IBAction func mediumGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium, value: self.viewModel.medium))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_regular"])
    self.updateGasPriceUIs()
  }

  @IBAction func slowGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow, value: self.viewModel.slow))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_slow"])
    self.updateGasPriceUIs()
  }

  @objc func userTappedSuperFastFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.superFast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .superFast, value: self.viewModel.superFast))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_super_fast"])
    self.updateGasPriceUIs()
  }

  @objc func userTappedFastFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast, value: self.viewModel.fast))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_fast"])
    self.updateGasPriceUIs()
  }

  @objc func userTappedMediumFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium, value: self.viewModel.medium))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_regular"])
    self.updateGasPriceUIs()
  }

  @objc func userTappedSlowFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow, value: self.viewModel.slow))
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "select_gas_slow"])
    self.updateGasPriceUIs()
  }

  @IBAction func threePercentButtonPressed(_ sender: Any) {
    self.viewModel.updateMinRateType(.threePercent)
    self.customRateTextField.text = ""
    self.customRateTextField.isEnabled = false
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
    self.updateMinRateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "slippage_rate_default"])
  }

  @objc func userTappedThreePercent(_ sender: Any) {
    self.threePercentButtonPressed(sender)
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "slippage_rate_default"])
  }

  @IBAction func customRateButtonPressed(_ sender: Any) {
    self.viewModel.updateMinRateType(.custom(value: 3.0))
    self.customRateTextField.text = "3.0"
    self.customRateTextField.isEnabled = true
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
    self.updateMinRateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "slippage_rate_custom"])
  }

  @objc func userTappedCustomRate(_ sender: Any) {
    self.customRateButtonPressed(sender)
    KNCrashlyticsUtil.logCustomEvent(withName: "swap_advanced_settings", customAttributes: ["action": "slippage_rate_custom"])
  }
}

extension KAdvancedSettingsView: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.removeGroupSeparator()
    let value: Double? = number.isEmpty ? 0 : Double(number)
    let maxMinRatePercent: Double = 100.0
    if let val = value, val >= 0, val <= maxMinRatePercent {
      textField.text = text
      self.viewModel.updateMinRateType(.custom(value: val))
      self.updateMinRateUIs()
      self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: CGFloat(val)))
    }
    return false
  }
}
