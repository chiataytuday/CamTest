//
//  ViewController.swift
//  CamTest
//
//  Created by debavlad on 07.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
	
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
	
	let expoPointImage: UIImageView = {
		let image = UIImage(systemName: "viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		imageView.alpha = 0
		return imageView
	}()
	
	var captureSession: AVCaptureSession?
	var frontDevice: AVCaptureDevice?
	var backDevice: AVCaptureDevice?
	var currentDevice: AVCaptureDevice?
	var previewLayer: AVCaptureVideoPreviewLayer?
	var photoOutput: AVCapturePhotoOutput?
	
	var exposurePb, focusPb: VerticalProgressBar!
	var activePb: VerticalProgressBar?
	var blackFrame: UIView!
	var poiOffset: CGPoint?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setCamera()
		setSubviews()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard poiOffset == nil else { return }
		guard let touch = touches.first?.location(in: view) else { return }
		guard expoPointImage.frame.contains(touch) else { return }
		
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.6, options: .curveEaseOut, animations: {
						self.expoPointImage.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
						self.poiOffset = CGPoint(x: touch.x - self.expoPointImage.frame.origin.x,
																		 y: touch.y - self.expoPointImage.frame.origin.y)
					}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = poiOffset {
			// poi
			expoPointImage.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			let point = previewLayer?.captureDevicePointConverted(fromLayerPoint: touch)
			do {
				try currentDevice?.lockForConfiguration()
				currentDevice?.exposurePointOfInterest = point!
				currentDevice?.exposureMode = .continuousAutoExposure
				lockButton.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
				currentDevice?.unlockForConfiguration()
				
			} catch { }
			
		} else {
			// pb
			if activePb == nil {
				activePb = touch.x > view.frame.width/2 ? focusPb : exposurePb
				activePb?.touchesBegan(touches, with: event)
			} else {
				activePb?.touchesMoved(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activePb?.touchesEnded(touches, with: event)
		activePb = nil
		poiOffset = nil
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.expoPointImage.transform = CGAffineTransform(scaleX: 1, y: 1)
		}, completion: nil)
	}
	
	private func exposureValueChanged() {
		do {
			try currentDevice?.lockForConfiguration()
			currentDevice?.setExposureTargetBias(Float(exposurePb!.value), completionHandler: nil)
			currentDevice?.unlockForConfiguration()
		} catch {}
	}
	
	private func focusValueChanged() {
		do {
			try currentDevice?.lockForConfiguration()
			currentDevice?.setFocusModeLocked(lensPosition: Float(focusPb!.value), completionHandler: nil)
			currentDevice?.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func shotButtonTapped() {
		let settings = AVCapturePhotoSettings()
		self.photoOutput?.capturePhoto(with: settings, delegate: self)
		blackFrame.alpha = 1
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
			self.blackFrame.alpha = 0
		}, completion: nil)
	}
	
	@objc private func lockButtonTapped() {
		do {
			UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
			let isContinuous = currentDevice?.exposureMode == .continuousAutoExposure
			
			lockButton.setImage(UIImage(systemName: isContinuous ? "lock.fill" : "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
			let transition = CATransition()
			transition.duration = 0.15
			transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			transition.type = CATransitionType.fade
			lockButton.imageView?.layer.add(transition, forKey: nil)
			
			try currentDevice?.lockForConfiguration()
			currentDevice?.exposureMode = isContinuous ? .locked : .continuousAutoExposure
			currentDevice?.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func flashButtonTapped() {
		UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
		let active = currentDevice?.isTorchActive
		flashButton.setImage(UIImage(systemName: active! ? "bolt.slash" : "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		let transition = CATransition()
		transition.duration = 0.15
		transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		transition.type = CATransitionType.fade
		flashButton.imageView?.layer.add(transition, forKey: nil)
		
		do {
			if currentDevice!.hasTorch {
				try currentDevice?.lockForConfiguration()
				currentDevice?.torchMode = currentDevice!.isTorchActive ? .off : .on
				currentDevice?.unlockForConfiguration()
			}
		} catch {}
	}
	
	private func setLineGrid() {
		let vert1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0, width: 1, height: view.frame.height))
		let vert2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0, width: 1, height: view.frame.height))
		let hor1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5, width: view.frame.width, height: 1))
		let hor2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5, width: view.frame.width, height: 1))
		
		for line in [vert1, vert2, hor1, hor2] {
			line.alpha = 0.25
			line.backgroundColor = .white
			line.addShadow(1, 0.5)
			view.addSubview(line)
		}
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
			currentDevice?.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
			currentDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: currentDevice!)
			captureSession?.addInput(deviceInput)
			photoOutput = AVCapturePhotoOutput()
			photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.h264])], completionHandler: nil)
			captureSession?.addOutput(photoOutput!)
		} catch {}
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer?.videoGravity = .resizeAspectFill
		previewLayer?.frame = view.frame
		previewLayer?.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer!, at: 0)
		
		captureSession?.startRunning()
	}
	
	private func setSubviews() {
		view.addSubview(shotButton)
		NSLayoutConstraint.activate([
			shotButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			shotButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			shotButton.widthAnchor.constraint(equalToConstant: 72.5),
			shotButton.heightAnchor.constraint(equalToConstant: 70)
		])
		shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchDown)
		
		let offset = view.frame.width/3
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
		
		exposurePb = VerticalProgressBar(frame: CGRect(x: 0, y: view.frame.midY, width: 55, height: 300), true, "sun.max.fill", "sun.min")
		exposurePb.delegate = exposureValueChanged
		exposurePb.alpha = 0
		view.addSubview(exposurePb)

		focusPb = VerticalProgressBar(frame: CGRect(x: view.frame.maxX, y: view.frame.midY, width: 55, height: 300), false, "plus.magnifyingglass", "minus.magnifyingglass")
		focusPb.delegate = focusValueChanged
		focusPb.alpha = 0
		view.addSubview(focusPb)
		
		blackFrame = UIView(frame: view.frame)
		blackFrame.backgroundColor = .black
		blackFrame.alpha = 0
		view.insertSubview(blackFrame, belowSubview: shotButton)
		
		flashButton.imageView!.addShadow(2.5, 0.3)
		shotButton.imageView!.addShadow(2.5, 0.3)
		lockButton.imageView!.addShadow(2.5, 0.3)
		expoPointImage.addShadow(1, 0.125)
		
		view.addSubview(expoPointImage)
		let point = previewLayer?.layerPointConverted(fromCaptureDevicePoint: currentDevice!.exposurePointOfInterest)
		expoPointImage.frame.origin = CGPoint(x: point!.x - expoPointImage.frame.width/2, y: point!.y - expoPointImage.frame.height/2)
		expoPointImage.alpha = 1
		
		setLineGrid()
	}
}

extension ViewController: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		if let imageData = photo.fileDataRepresentation() {
			UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)
		}
	}
}

extension UIView {
	func addShadow(_ radius: CGFloat, _ opacity: Float) {
		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
		self.layer.shadowOpacity = opacity
		self.layer.shadowRadius = radius
		self.clipsToBounds = false
	}
}
