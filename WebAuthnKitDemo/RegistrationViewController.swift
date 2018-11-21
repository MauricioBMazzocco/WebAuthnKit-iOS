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
        
        var options = PublicKeyCredentialCreationOptions()
        options.challenge = Bytes.fromString("hogehoge")
        options.user.id = Bytes.fromUInt64(12345)
        options.user.name = "john"
        options.user.displayName = "John"
        options.rp.id = "https://example.org"
        options.rp.name = "MyService"
        options.attestation = .direct // .indirect, .none
        options.addPubKeyCredParam(alg: .rs256)
        options.authenticatorSelection = AuthenticatorSelectionCriteria(
            requireResidentKey: true,
            userVerification: .required
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WAKLogger.available = true
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Registration"
        
        self.setupTitleLabel()
        self.setupStartButton()
        self.setupWebAuthnClient()
    }
    
    private func setupTitleLabel() {
        let label = ViewCatalog.createLabel(text: "Registration Process")
        label.height(30)
        label.fitScreenW(10)
        label.centerizeScreenH()
        label.top(120)
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor.white
        view.addSubview(label)
    }
    
    private func setupStartButton() {
        let button = ViewCatalog.createButton(text: "START")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onStartButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(250)
        
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
        let attestationObject = credential.response.attestationObject.toHexString()

        let vc = ResultViewController(
            rawId:             rawId,
            hashedId:          hashedId,
            clientDataJSON:    clientDataJSON,
            attestationObject: attestationObject
        )
        
        self.present(vc, animated: true, completion: nil)
    }
}

