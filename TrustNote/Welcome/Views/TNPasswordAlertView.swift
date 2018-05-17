//
//  TNPasswordAlertView.swift
//  TrustNote
//
//  Created by zenghailong on 2018/5/10.
//  Copyright © 2018年 org.trustnote. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TNPasswordAlertView: UIView, TNNibLoadable {
    
    typealias ClickedButtonBlock = () -> Void
    let disposeBag = DisposeBag()
    
    var verifyCorrectBlock: ClickedButtonBlock?
    var didClickedCancelBlock: ClickedButtonBlock?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var errorView: UIView!
    
    @IBOutlet weak var errorTipLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupProperties()
        cancelButton.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            UIView.animate(withDuration: 0.5,
                           delay:0.01,
                           options:UIViewAnimationOptions.curveEaseInOut,
                           animations:{ ()-> Void in
                            self.removeFromSuperview()
            },
                           completion:{(finished:Bool) -> Void in}
            )
            if let didClickedCancelBlock = self.didClickedCancelBlock {
                didClickedCancelBlock()
            }
            
        }).disposed(by: disposeBag)
        
        confirmButton.rx.tap.asObservable().subscribe(onNext: { [unowned self] _ in
            self.didClickedConfirmButton()
        }).disposed(by: disposeBag)
    }
}

extension TNPasswordAlertView {
    
    fileprivate func setupProperties() {
        titleLabel.text = NSLocalizedString("Input password", comment: "")
        passwordTextField.placeholder = NSLocalizedString("Please input password", comment: "")
        errorTipLabel.text = NSLocalizedString("Verify password error", comment: "")
        confirmButton.setTitle(NSLocalizedString("Confirm", comment: ""), for: .normal)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        confirmButton.setupRadiusCorner(radius: kCornerRadius)
        cancelButton.setupRadiusCorner(radius: kCornerRadius)
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.borderColor = kGlobalColor.cgColor
        passwordTextField.delegate = self
    }
}

/// MARK: EVENT HANDLE
extension TNPasswordAlertView {
    
    fileprivate func shakeAnimation() {
        errorView.shakeAnimation(scope: 5.0)
    }
    
    fileprivate func didClickedConfirmButton() {
        let md5Value = passwordTextField.text?.md5()
        guard md5Value == Preferences[.encryptionPassword] else {
            errorView.isHidden = false
            shakeAnimation()
            return
        }
        TNGlobalHelper.shared.password = passwordTextField.text
        if !TNGlobalHelper.shared.encryptePrivKey.isEmpty {
            
            TNEvaluateScriptManager.sharedInstance.getEcdsaPrivkey(xPrivKey: TNGlobalHelper.shared.xPrivKey, completed: {
                TNHubViewModel.loginHub()
            })
            TNEvaluateScriptManager.sharedInstance.generateRootPublicKey(xPrivKey: TNGlobalHelper.shared.xPrivKey)
        }
        passwordTextField.resignFirstResponder()
        verifyCorrectBlock!()
    }
}

extension TNPasswordAlertView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !errorView.isHidden {
            errorView.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}