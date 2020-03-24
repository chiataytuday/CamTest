//
//  PermissionsController.swift
//  CamTest
//
//  Created by debavlad on 21.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import Photos

class PermissionsController: UIViewController {
	
	let buttonNext: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Grant to start", for: .normal)
		button.setTitleColor(.systemGray4, for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .light)
		return button
	}()
	
	var nextViewController: ViewController!
	var cameraButton, libraryButton, micButton: UIButton!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor(red: 12/255, green: 12/255, blue: 12/255, alpha: 1)
		setupButtons()
	}
	
	private func setupButtons() {
		libraryButton = grantButton("photo.fill")
		buttonAppearance(libraryButton, PHPhotoLibrary.authorizationStatus() == .authorized)
		libraryButton.addTarget(self, action: #selector(libraryButtonAction), for: .touchDown)
		view.addSubview(libraryButton)
		NSLayoutConstraint.activate([
			libraryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			libraryButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
		
		cameraButton = grantButton("camera.fill")
		buttonAppearance(cameraButton, AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
		cameraButton.addTarget(self, action: #selector(cameraButtonAction), for: .touchDown)
		view.addSubview(cameraButton)
		NSLayoutConstraint.activate([
			cameraButton.trailingAnchor.constraint(equalTo: libraryButton.leadingAnchor, constant: -15),
			cameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		
		micButton = grantButton("mic.fill")
		buttonAppearance(micButton, AVAudioSession.sharedInstance().recordPermission == .granted)
		micButton.addTarget(self, action: #selector(micButtonAction), for: .touchDown)
		view.addSubview(micButton)
		NSLayoutConstraint.activate([
			micButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 15),
			micButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		
		view.addSubview(buttonNext)
		NSLayoutConstraint.activate([
			buttonNext.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			buttonNext.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			buttonNext.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			buttonNext.heightAnchor.constraint(equalToConstant: 115)
		])
		
		// MARK: - Animation
		
		UIView.animate(withDuration: 0.5, delay: 0.12, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.libraryButton.transform = CGAffineTransform(translationX: 0, y: 10)
			self.cameraButton.transform = CGAffineTransform(translationX: 0, y: 10)
			self.micButton.transform = CGAffineTransform(translationX: 0, y: 10)
			self.libraryButton.alpha = 1
			self.cameraButton.alpha = 1
			self.micButton.alpha = 1
		}, completion: nil)
	}
	
	
	@objc private func libraryButtonAction() {
		if PHPhotoLibrary.authorizationStatus() == .denied {
			showAlert("Photo Library Access Denied", "Photo Library access was previously denied. You must grant it through system settings")
		} else {
			PHPhotoLibrary.requestAuthorization { (status) in
				if status != .authorized { return }
				self.buttonAppearance(self.libraryButton, true)
			}
		}
	}
	
	@objc private func cameraButtonAction() {
		if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
			showAlert("Camera Access Denied", "Camera access was previously denied. You must grant it through system settings")
		} else {
			AVCaptureDevice.requestAccess(for: .video) { (granted) in
				if !granted { return }
				self.buttonAppearance(self.cameraButton, true)
			}
		}
	}
	
	@objc private func micButtonAction() {
		if AVAudioSession.sharedInstance().recordPermission == .denied {
			showAlert("Microphone Access Denied", "Microphone access was previously denied. You must grant it through system settings")
		} else {
			AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
				if !granted { return }
				self.buttonAppearance(self.micButton, true)
			}
		}
	}
	
	
	private func grantButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27, weight: .light), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.tintColor = .systemGray2
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.layer.cornerRadius = 17.5
		button.alpha = 0
		button.adjustsImageWhenHighlighted = false
		
		NSLayoutConstraint.activate([
			button.widthAnchor.constraint(equalToConstant: 70),
			button.heightAnchor.constraint(equalToConstant: 70)
		])
		return button
	}
	
	private func showAlert(_ title: String, _ message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
		alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
			if let url = URL(string: UIApplication.openSettingsURLString) {
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
		}))
		self.present(alert, animated: true)
	}
	
	private func buttonAppearance(_ button: UIButton, _ accessGranted: Bool) {
		DispatchQueue.main.async {
			if accessGranted {
				button.backgroundColor = .systemGray2
				button.layer.borderColor = UIColor.systemGray2.cgColor
				button.tintColor = .black
			} else {
				button.backgroundColor = UIColor(red: 12/255, green: 12/255, blue: 12/255, alpha: 1)
				button.layer.borderColor = UIColor.systemGray5.cgColor
				button.tintColor = .systemGray2
			}
			
			guard let vc = self.nextViewController, PermissionsController.grantedCount() == 3 else { return }
			self.present(vc, animated: true)
		}
	}
	
	static func grantedCount() -> Int {
		var granted = 0
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			granted += 1
		}
		if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
			granted += 1
		}
		if AVAudioSession.sharedInstance().recordPermission == .granted {
			granted += 1
		}
		return granted
	}
}
