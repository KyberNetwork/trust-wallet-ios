// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KYCFlowViewEvent {
  case back
  case submitted
}

protocol KYCFlowViewControllerDelegate: class {
  func kycFlowViewController(_ controller: KYCFlowViewController, run event: KYCFlowViewEvent)
}

class KYCFlowViewModel {
  let user: IEOUser
  var stepState: KNKYCStepViewState

  fileprivate(set) var firstName: String = ""
  fileprivate(set) var lastName: String = ""
  fileprivate(set) var gender: String = ""
  fileprivate(set) var dob: String = ""
  fileprivate(set) var nationality: String = ""
  fileprivate(set) var residenceCountry: String = ""
  fileprivate(set) var docType: String = ""
  fileprivate(set) var docNumber: String = ""
  fileprivate(set) var docImage: UIImage!
  fileprivate(set) var docHoldingImage: UIImage!

  init(user: IEOUser) {
    self.user = user
    self.stepState = .personalInfo
  }

  func updateStepState(_ step: KNKYCStepViewState) {
    self.stepState = step
  }

  func updatePersonalInfo(firstName: String, lastName: String, gender: String, dob: String, nationality: String, residenceCountry: String) {
    self.firstName = firstName
    self.lastName = lastName
    self.gender = gender
    self.dob = dob
    self.nationality = nationality
    self.residenceCountry = residenceCountry
  }

  func updateIdentityInfo(docType: String, docNum: String, docImage: UIImage, docHoldingImage: UIImage) {
    self.docType = docType
    self.docNumber = docNum
    self.docImage = docImage
    self.docHoldingImage = docHoldingImage
  }
}

class KYCFlowViewController: KNBaseViewController {

  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var stepView: KNKYCStepView!
  @IBOutlet weak var scrollView: UIScrollView!

  fileprivate var submitInfoVC: KYCSubmitInfoViewController!

  fileprivate var viewModel: KYCFlowViewModel
  weak var delegate: KYCFlowViewControllerDelegate?

  init(viewModel: KYCFlowViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KYCFlowViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupStepView()
    self.setupPersonalInfoView()
  }

  fileprivate func setupStepView() {
    self.navigationTitleLabel.text = self.viewModel.stepState.title
    self.stepView.updateView(with: self.viewModel.stepState)
  }

  fileprivate func setupPersonalInfoView() {
    let width = self.view.frame.width
    let height = self.view.frame.height - self.scrollView.frame.minY

    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: width,
      height: height
    )

    let personalInfoVC: KYCPersonalInfoViewController = {
      let viewModel = KYCPersonalInfoViewModel(user: self.viewModel.user)
      let controller = KYCPersonalInfoViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.addChildViewController(personalInfoVC)
    personalInfoVC.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    self.scrollView.addSubview(personalInfoVC.view)
    personalInfoVC.didMove(toParentViewController: self)

    let identityInfoVC: KYCIdentityInfoViewController = {
      let viewModel = KYCIdentityInfoViewModel()
      let controller = KYCIdentityInfoViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.addChildViewController(identityInfoVC)
    identityInfoVC.view.frame = CGRect(x: width, y: 0, width: width, height: height)
    self.scrollView.addSubview(identityInfoVC.view)
    identityInfoVC.didMove(toParentViewController: self)

    self.submitInfoVC = {
      let viewModel = KYCSubmitInfoViewModel(
        firstName: self.viewModel.firstName,
        lastName: self.viewModel.lastName,
        gender: self.viewModel.gender,
        dob: self.viewModel.dob,
        nationality: self.viewModel.nationality,
        residenceCountry: self.viewModel.residenceCountry,
        docType: self.viewModel.docType,
        docNum: self.viewModel.docNumber,
        docImage: self.viewModel.docImage,
        docHoldingImage: self.viewModel.docHoldingImage
      )
      let controller = KYCSubmitInfoViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.addChildViewController(self.submitInfoVC)
    self.submitInfoVC.view.frame = CGRect(x: 2.0 * width, y: 0, width: width, height: height)
    self.scrollView.addSubview(self.submitInfoVC.view)
    self.submitInfoVC.didMove(toParentViewController: self)

    let statusVC: KYCProfileVerificationStatusViewController = {
      return KYCProfileVerificationStatusViewController()
    }()
    self.addChildViewController(statusVC)
    statusVC.view.frame = CGRect(x: 3.0 * width, y: 0, width: width, height: height)
    self.scrollView.addSubview(statusVC.view)
    statusVC.didMove(toParentViewController: self)

    self.scrollView.contentSize = CGSize(
      width: self.scrollView.frame.width * 4.0,
      height: 1.0
    )
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    if self.viewModel.stepState != .personalInfo && self.viewModel.stepState != .done {
      let newState: KNKYCStepViewState = {
        switch self.viewModel.stepState {
        case .personalInfo:
          return .personalInfo
        default:
          return KNKYCStepViewState(rawValue: self.viewModel.stepState.rawValue - 1) ?? .personalInfo
        }
      }()
      self.updateViewState(newState: newState)
    } else {
      let event: KYCFlowViewEvent = self.viewModel.stepState == .personalInfo ? .back : .submitted
      self.delegate?.kycFlowViewController(self, run: event)
    }
  }

  fileprivate func updateViewState(newState: KNKYCStepViewState) {
    let width = self.view.frame.width
    let height = self.view.frame.height - self.scrollView.frame.minY

    self.viewModel.updateStepState(newState)
    self.stepView.updateView(with: self.viewModel.stepState)
    self.navigationTitleLabel.text = self.viewModel.stepState.title

    let rect = CGRect(
      x: CGFloat(self.viewModel.stepState.rawValue) * width,
      y: 0,
      width: width,
      height: height
    )
    if newState == .submit {
      let viewModel = KYCSubmitInfoViewModel(
        firstName: self.viewModel.firstName,
        lastName: self.viewModel.lastName,
        gender: self.viewModel.gender,
        dob: self.viewModel.dob,
        nationality: self.viewModel.nationality,
        residenceCountry: self.viewModel.residenceCountry,
        docType: self.viewModel.docType,
        docNum: self.viewModel.docNumber,
        docImage: self.viewModel.docImage,
        docHoldingImage: self.viewModel.docHoldingImage
      )
      self.submitInfoVC.updateViewModel(viewModel)
    }
    self.scrollView.scrollRectToVisible(rect, animated: true)
  }
}

extension KYCFlowViewController: KYCPersonalInfoViewControllerDelegate {
  func kycPersonalInfoViewController(_ controller: KYCPersonalInfoViewController, run event: KYCPersonalInfoViewEvent) {
    switch event {
    case .next(let firstName, let lastName, let gender, let dob, let nationality, let country):
      self.viewModel.updatePersonalInfo(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dob: dob,
        nationality: nationality,
        residenceCountry: country
      )
      self.updateViewState(newState: .id)
    }
  }
}

extension KYCFlowViewController: KYCIdentityInfoViewControllerDelegate {
  func identityInfoViewController(_ controller: KYCIdentityInfoViewController, run event: KYCIdentityInfoViewEvent) {
    switch event {
    case .next(let docType, let docNum, let docImage, let docHoldingImage):
      self.viewModel.updateIdentityInfo(
        docType: docType,
        docNum: docNum,
        docImage: docImage,
        docHoldingImage: docHoldingImage
      )
      self.updateViewState(newState: .submit)
    }
  }
}

extension KYCFlowViewController: KYCSubmitInfoViewControllerDelegate {
  func submitInfoViewController(_ controller: KYCSubmitInfoViewController, run event: KYCSubmitInfoViewEvent) {
    switch event {
    case .submit:
      self.updateViewState(newState: .done)
      print("Sending submit request")
    }
  }
}
