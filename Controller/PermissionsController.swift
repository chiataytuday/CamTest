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
	
	let circleLogo: UIImageView = {
		let image = UIImage(systemName: "circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemGray3
		return imageView
	}()
	
	let buttonNext: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Grant to start", for: .normal)
		button.setTitleColor(.systemGray4, for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .light)
		return button
	}()
	
	let cameraButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27.5, weight: .light), forImageIn: .normal)
		button.setImage(UIImage(systemName: "camera.fill"), for: .normal)
		button.tintColor = .systemGray2
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.layer.cornerRadius = 17.5
		return button
	}()
	
	let libraryButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27.5, weight: .light), forImageIn: .normal)
		button.setImage(UIImage(systemName: "photo.fill"), for: .normal)
		button.tintColor = .systemGray2
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.layer.cornerRadius = 17.5
		return button
	}()
	
	let micButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27.5, weight: .light), forImageIn: .normal)
		button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
		button.tintColor = .systemGray2
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.layer.cornerRadius = 17.5
		return button
	}()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		circleLogo.center = CGPoint(x: view.center.x, y: 80)
		circleLogo.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
		view.addSubview(circleLogo)
		
		view.addSubview(libraryButton)
		libraryButton.addTarget(self, action: #selector(libraryButtonAction), for: .touchDown)
		NSLayoutConstraint.activate([
			libraryButton.widthAnchor.constraint(equalToConstant: 70),
			libraryButton.heightAnchor.constraint(equalToConstant: 70),
			libraryButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			libraryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		view.addSubview(cameraButton)
		cameraButton.addTarget(self, action: #selector(cameraButtonAction), for: .touchDown)
		NSLayoutConstraint.activate([
			cameraButton.widthAnchor.constraint(equalToConstant: 70),
			cameraButton.heightAnchor.constraint(equalToConstant: 70),
			cameraButton.trailingAnchor.constraint(equalTo: libraryButton.leadingAnchor, constant: -15),
			cameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		
		view.addSubview(micButton)
		micButton.addTarget(self, action: #selector(micButtonAction), for: .touchDown)
		NSLayoutConstraint.activate([
			micButton.widthAnchor.constraint(equalToConstant: 70),
			micButton.heightAnchor.constraint(equalToConstant: 70),
			micButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			micButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 15)
		])
		
		view.addSubview(buttonNext)
		NSLayoutConstraint.activate([
			buttonNext.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			buttonNext.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			buttonNext.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			buttonNext.heightAnchor.constraint(equalToConstant: 115)
		])
		
		checkPermissions()
	}
	
	@objc func libraryButtonAction() {
		if PHPhotoLibrary.authorizationStatus() == .denied {
			showAlert("Photo Library Access Denied", "Photo Library access was previously denied. You must grant it through system settings")
		} else {
			PHPhotoLibrary.requestAuthorization { (status) in
				if status == .authorized {
					self.buttonAppearance(self.libraryButton, true)
				}
			}
		}
	}
	
	@objc func cameraButtonAction() {
		if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
			showAlert("Camera Access Denied", "Camera access was previously denied. You must grant it through system settings")
		} else {
			AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
				if response {
					self.buttonAppearance(self.cameraButton, response)
				}
			}
		}
	}
	
	@objc func micButtonAction() {
		if AVAudioSession.sharedInstance().recordPermission == .denied {
			showAlert("Microphone Access Denied", "Microphone access was previously denied. You must grant it through system settings")
		} else {
			AVAudioSession.sharedInstance().requestRecordPermission { (response) in
				if response {
					self.buttonAppearance(self.micButton, response)
				}
			}
		}
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
	
	private func checkPermissions() {
		let libraryGranted = PHPhotoLibrary.authorizationStatus() == .authorized
		buttonAppearance(libraryButton, libraryGranted)
		let cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
		buttonAppearance(cameraButton, cameraGranted)
		let micGranted = AVAudioSession.sharedInstance().recordPermission == .granted
		buttonAppearance(micButton, micGranted)
	}
	
	private func buttonAppearance(_ button: UIButton, _ accessGranted: Bool) {
		DispatchQueue.main.async {
			if accessGranted {
				button.backgroundColor = .systemGray2
				button.layer.borderColor = UIColor.systemGray2.cgColor
				button.tintColor = .black
			} else {
				button.backgroundColor = .black
				button.layer.borderColor = UIColor.systemGray5.cgColor
				button.tintColor = .systemGray2
			}
		}
	}
}
