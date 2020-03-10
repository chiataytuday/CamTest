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
	let expoPointImage: UIImageView = {
		let image = UIImage(systemName: "smallcircle.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60, weight: .thin))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemRed
		imageView.alpha = 0
		return imageView
	}()
	
	let shotButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "largecircle.fill.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 70, weight: .thin)), for: .normal)
		button.tintColor = .white
		return button
	}()
	
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
		view.addSubview(expoPointImage)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		let pointLocation = CGPoint(x: touch.x - expoPointImage.frame.width/2,
																	 y: touch.y - expoPointImage.frame.height/2)
		expoPointImage.frame.origin = pointLocation
		expoPointImage.alpha = 1
		
		let exposurePoint = previewLayer!.captureDevicePointConverted(fromLayerPoint: touch)
		print(exposurePoint)
		do {
			try currentDevice?.lockForConfiguration()
			currentDevice?.exposurePointOfInterest = exposurePoint
			currentDevice?.exposureMode = .continuousAutoExposure
			lockButton.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
			currentDevice?.unlockForConfiguration()
		} catch { }
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
		view.addSubview(shotButton)
		NSLayoutConstraint.activate([
			shotButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			shotButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			shotButton.widthAnchor.constraint(equalToConstant: 72.5),
			shotButton.heightAnchor.constraint(equalToConstant: 70)
		])
		
		let offset = view.frame.width/2.6
		view.addSubview(flashButton)
		NSLayoutConstraint.activate([
			flashButton.centerYAnchor.constraint(equalTo: shotButton.centerYAnchor),
			flashButton.widthAnchor.constraint(equalToConstant: 50),
			flashButton.heightAnchor.constraint(equalToConstant: 50),
			flashButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchDown)
		
		view.addSubview(lockButton)
		NSLayoutConstraint.activate([
			lockButton.centerYAnchor.constraint(equalTo: shotButton.centerYAnchor),
			lockButton.widthAnchor.constraint(equalToConstant: 50),
			lockButton.heightAnchor.constraint(equalToConstant: 50),
			lockButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
		lockButton.addTarget(self, action: #selector(lockButtonTapped), for: .touchDown)
		
		let leftPb = VerticalProgressBar(frame: CGRect(x: 0, y: view.frame.midY, width: 55, height: 300), true, "sun.min", "sun.max.fill")
		view.addSubview(leftPb)
		
		let rightPb = VerticalProgressBar(frame: CGRect(x: view.frame.maxX, y: view.frame.midY, width: 55, height: 300), false, "plus.magnifyingglass", "minus.magnifyingglass")
		view.addSubview(rightPb)
		
//		expoSlider.translatesAutoresizingMaskIntoConstraints = false
//		expoSlider.minimumValue = currentDevice!.minExposureTargetBias/3
//		expoSlider.maximumValue = currentDevice!.maxExposureTargetBias/3
//		expoSlider.addTarget(self, action: #selector(expoSliderValueChanged(sender:)), for: .valueChanged)
//		view.addSubview(expoSlider)
//		NSLayoutConstraint.activate([
//			expoSlider.centerYAnchor.constraint(equalTo: lockButton.centerYAnchor),
//			expoSlider.leadingAnchor.constraint(equalTo: lockButton.trailingAnchor, constant: 25),
//			expoSlider.trailingAnchor.constraint(equalTo: flashButton.leadingAnchor, constant: -25)
//		])
	}
	
//	@objc private func expoSliderValueChanged(sender: UISlider) {
//		do {
//			try currentDevice?.lockForConfiguration()
//			currentDevice?.exposureMode = .autoExpose
//			currentDevice?.setExposureTargetBias(expoSlider.value, completionHandler: nil)
//			currentDevice?.unlockForConfiguration()
//		} catch {}
//	}
	
	@objc private func lockButtonTapped() {
		do {
			let isContinuous = currentDevice?.exposureMode == .continuousAutoExposure
			lockButton.setImage(UIImage(systemName: isContinuous ? "lock.fill" : "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
			try currentDevice?.lockForConfiguration()
			currentDevice?.exposureMode = isContinuous ? .locked : .continuousAutoExposure
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
			photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.h264])], completionHandler: nil)
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
