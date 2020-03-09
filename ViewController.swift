//
//  ViewController.swift
//  CamTest
//
//  Created by debavlad on 07.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	let expoSlider = UISlider()
	
	let flashButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "bolt.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.tintColor = .white
		return button
	}()
	
	let lockButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.tintColor = .white
		return button
	}()
	
	var captureSession: AVCaptureSession?
	var frontDevice: AVCaptureDevice?
	var backDevice: AVCaptureDevice?
	var currentDevice: AVCaptureDevice?
	
	var previewLayer: AVCaptureVideoPreviewLayer?
	var photoOutput: AVCapturePhotoOutput?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setCamera()
		setButtons()
	}
	
//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		let touch = touches.first!.location(in: view)
//		let point = CGPoint(x: touch.x/view.frame.width, y: touch.y/view.frame.height)
//
//		do {
//			try currentDevice?.lockForConfiguration()
//			currentDevice?.exposureMode = .custom
//			currentDevice?.exposurePointOfInterest = point
//			currentDevice?.exposureMode = .locked
//			lockButton.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
//			currentDevice?.unlockForConfiguration()
//		} catch {}
//	}
	
	private func setButtons() {
		view.addSubview(flashButton)
		NSLayoutConstraint.activate([
			flashButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			flashButton.widthAnchor.constraint(equalToConstant: 50),
			flashButton.heightAnchor.constraint(equalToConstant: 50),
			flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25)
		])
		flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchDown)
		
		view.addSubview(lockButton)
		NSLayoutConstraint.activate([
			lockButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			lockButton.widthAnchor.constraint(equalToConstant: 50),
			lockButton.heightAnchor.constraint(equalToConstant: 50),
			lockButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25)
		])
		lockButton.addTarget(self, action: #selector(lockButtonTapped), for: .touchDown)
		
		expoSlider.translatesAutoresizingMaskIntoConstraints = false
		expoSlider.minimumValue = currentDevice!.minExposureTargetBias/2
		expoSlider.maximumValue = currentDevice!.maxExposureTargetBias/2
		expoSlider.addTarget(self, action: #selector(expoSliderValueChanged(sender:)), for: .valueChanged)
		view.addSubview(expoSlider)
		NSLayoutConstraint.activate([
			expoSlider.centerYAnchor.constraint(equalTo: lockButton.centerYAnchor),
			expoSlider.leadingAnchor.constraint(equalTo: lockButton.trailingAnchor, constant: 25),
			expoSlider.trailingAnchor.constraint(equalTo: flashButton.leadingAnchor, constant: -25)
		])
	}
	
	@objc private func expoSliderValueChanged(sender: UISlider) {
		do {
			try currentDevice?.lockForConfiguration()
			currentDevice?.exposureMode = .autoExpose
			currentDevice?.setExposureTargetBias(expoSlider.value, completionHandler: nil)
			currentDevice?.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func lockButtonTapped() {
		do {
			let isContinuous = currentDevice?.exposureMode == .continuousAutoExposure
			lockButton.setImage(UIImage(systemName: isContinuous ? "lock.fill" : "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
			try currentDevice?.lockForConfiguration()
			currentDevice?.exposureMode = isContinuous ? .autoExpose : .continuousAutoExposure
			currentDevice?.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func flashButtonTapped() {
		let active = currentDevice?.isTorchActive
		flashButton.setImage(UIImage(systemName: active! ? "bolt.slash" : "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		do {
			if currentDevice!.hasTorch {
				try currentDevice?.lockForConfiguration()
				currentDevice?.torchMode = currentDevice!.isTorchActive ? .off : .on
				currentDevice?.unlockForConfiguration()
			}
		} catch {}
	}
	
	private func setCamera() {
		// Session
		captureSession = AVCaptureSession()
		captureSession?.sessionPreset = .hd1920x1080
		
		// Devices
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		for device in devices {
			if device.position == .front {
				frontDevice = device
			} else if device.position == .back {
				backDevice = device
			}
		}
		currentDevice = backDevice
		
		do {
			try currentDevice?.lockForConfiguration()
			currentDevice?.setFocusModeLocked(lensPosition: 0, completionHandler: nil)
			currentDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: currentDevice!)
			captureSession?.addInput(deviceInput)
			photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
		} catch {}
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer?.videoGravity = .resizeAspectFill
		previewLayer?.frame = view.frame
		previewLayer?.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer!, at: 0)
		
		captureSession?.startRunning()
	}
}
