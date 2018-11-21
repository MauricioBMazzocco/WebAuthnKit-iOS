//
//  RegistrationViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import WebAuthnKit
import PromiseKit
import CryptoSwift

public enum FormError : Error {
    case missing(String)
    case empty(String)
}

class RegistrationViewController: UIViewController {
    
    var webAuthnClient: WebAuthnClient!
    var userConsentUI: UserConsentUI!
    
    private func setupWebAuthnClient() {
        
        self.userConsentUI = UserConsentUI(viewController: self)
        
        // Registration Phase: These messages are shown for UserVerification/UserPresenceCheck popup.
        self.userConsentUI.confirmationPopupTitle = "Use Key"
        self.userConsentUI.confirmationPopupMessageBuilder = { rp, user in
            return "Create new key for \(user.displayName)?"
        }
        
        // Registration Phase: These messages are shown for confirmation popup when 'exclude' list is set.
        self.userConsentUI.newCredentialPopupTitle = "New Key"
        self.userConsentUI.newCredentialPopupMessage = "Create New Key for this service?"
        
        // Authentication Phase: These messages are shown for key-selection popup.
        self.userConsentUI.selectionPopupTitle = "Key Selection"
        self.userConsentUI.selectionPopupMessage = "Key Selection"
        
        let authenticator = InternalAuthenticator(
            ui:            self.userConsentUI,
            encryptionKey: Bytes.fromString("hogehogehogehoge") // 16byte
        )
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startRegistration() {
        
        guard let challenge = self.challengeText.text else {
            self.showErrorPopup(FormError.missing("challenge"))
            return
        }
        if challenge.isEmpty {
            self.showErrorPopup(FormError.empty("challenge"))
            return
        }
        
        guard let userId = self.userIdText.text else {
            self.showErrorPopup(FormError.missing("userId"))
            return
        }
        if userId.isEmpty {
            self.showErrorPopup(FormError.empty("userId"))
            return
        }
        
        guard let rpId = self.rpIdText.text else {
            self.showErrorPopup(FormError.missing("rpId"))
            return
        }
        if rpId.isEmpty {
            self.showErrorPopup(FormError.empty("rpId"))
            return
        }
        
        let attestation = [
            AttestationConveyancePreference.direct,
            AttestationConveyancePreference.indirect,
            AttestationConveyancePreference.none,
        ][self.attestationConveyance.selectedSegmentIndex]
        
        let verification = [
            UserVerificationRequirement.required,
            UserVerificationRequirement.preferred,
            UserVerificationRequirement.discouraged
        ][self.userVerification.selectedSegmentIndex]
        
        let requireResidentKey = [true, false][self.residentKeyRequired.selectedSegmentIndex]
        
        var options = PublicKeyCredentialCreationOptions()
        options.challenge = Bytes.fromHex(challenge)
        options.user.id = Bytes.fromString(userId)
        options.user.name = "john"
        options.user.displayName = "John"
        options.rp.id = rpId
        options.rp.name = "MyService"
        options.attestation = attestation
        options.addPubKeyCredParam(alg: .rs256)
        options.authenticatorSelection = AuthenticatorSelectionCriteria(
            requireResidentKey: requireResidentKey,
            userVerification: verification
        )
        // options.timeout = UInt64(120)

        firstly {
            
            self.webAuthnClient.create(options)
            
        }.done { credential in

            self.showResult(credential)

        }.catch { error in

            self.showErrorPopup(error)
        }
        
    }
    
    private func showErrorPopup(_ error: Error) {
        
        let alert = UIAlertController.init(
            title:          "ERROR",
            message:        "failed: \(error)",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction.init(title: "OK", style: .default)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    var userIdText:            UITextView!
    var rpIdText:              UITextView!
    var challengeText:         UITextView!
    var userVerification:      UISegmentedControl!
    var attestationConveyance: UISegmentedControl!
    var residentKeyRequired:   UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WAKLogger.available = true
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Registration"
        
        let offset: CGFloat = 50
        
        self.newLabel(text: "User Id", top: offset + 60)
        self.userIdText = self.newTextView(height: 30, top: offset + 90, text: "")
        
        self.newLabel(text: "Relying Party Id", top: offset + 130)
        self.rpIdText = self.newTextView(height: 30, top: offset + 160, text: "https://example.org")
        
        self.newLabel(text: "Challenge (Hex)", top: offset + 200)
        self.challengeText = self.newTextView(height: 30, top: offset + 230, text: "aed9c789543b")
        
        self.newLabel(text: "User Verification", top: offset + 280)
        self.userVerification = self.newSegmentedControl(top: offset + 310, list: ["Required", "Preferred", "Discouraged"])
        
        self.newLabel(text: "Attestation Conveyance", top: offset + 360)
        self.attestationConveyance = self.newSegmentedControl(top: offset + 390, list: ["Direct", "Indirect", "None"])

        self.newLabel(text: "Resident Key Required", top: offset + 440)
        self.residentKeyRequired = self.newSegmentedControl(top: offset + 470, list: ["Required", "Not Required"])

        self.setupStartButton()
        self.setupWebAuthnClient()
    }
    
    private func newLabel(text: String, top: CGFloat) {
        let label = ViewCatalog.createLabel(text: text)
        label.height(20)
        label.fitScreenW(10)
        label.centerizeScreenH()
        label.top(top)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.white
        view.addSubview(label)
    }
    
    private func newSegmentedControl(top: CGFloat, list: [String]) -> UISegmentedControl {
        let seg = UISegmentedControl(items: list)
        seg.fitScreenW(20)
        seg.selectedSegmentIndex = 0
        seg.top(top)
        seg.tintColor = UIColor.fromRGB(0xff8c00)
        seg.backgroundColor = UIColor.black
        view.addSubview(seg)
        seg.centerizeScreenH()
        return seg
    }
    
    private func newTextView(height: CGFloat, top: CGFloat, text: String) -> UITextView {
        let view = ViewCatalog.createTextView()
        view.text = text
        view.fitScreenW(20)
        view.height(height)
        view.top(top)
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.backgroundColor = UIColor.white
        view.textColor = UIColor.black
        self.view.addSubview(view)
        view.centerizeScreenH()
        return view
    }
    
    private func setupStartButton() {
        let button = ViewCatalog.createButton(text: "START")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onStartButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(self.view.bounds.height - 50 - 50)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    @objc func onStartButtonTapped(_ sender: UIButton) {
        self.startRegistration()
    }
    
    private func showResult(_ credential: WebAuthnClient.CreateResponse) {
        
        let rawId             = credential.rawId.toHexString()
        let hashedId          = credential.id
        let clientDataJSON    = credential.response.clientDataJSON
        let attestationObject = Base64.encodeBase64URL(credential.response.attestationObject)

        let vc = ResultViewController(
            rawId:             rawId,
            hashedId:          hashedId,
            clientDataJSON:    clientDataJSON,
            attestationObject: attestationObject
        )
        
        self.present(vc, animated: true, completion: nil)
    }
}
