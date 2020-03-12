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
	
	let shotBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "largecircle.fill.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 70, weight: .thin)), for: .normal)
		button.tintColor = .white
		return button
	}()
	
	let lightBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "bolt.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.tintColor = .white
		return button
	}()
	
	let lockBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.tintColor = .white
		return button
	}()
	
	let exposureView: UIImageView = {
		let image = UIImage(systemName: "viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		imageView.alpha = 0
		return imageView
	}()
	
	var captureSession: AVCaptureSession?
	var captureDevice: AVCaptureDevice?
	var previewLayer: AVCaptureVideoPreviewLayer?
	var photoOutput: AVCapturePhotoOutput?
	
	var exposureBar, focusBar: VerticalProgressBar!
	var activeBar: VerticalProgressBar?
	var poiOffset: CGPoint?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setCamera()
		setButtons()
		setSliders()
		setPoint()
		setLineGrid()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard poiOffset == nil, let t = touches.first?.location(in: view),
			exposureView.frame.contains(t) else { return }
		
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.6, options: .curveEaseOut, animations: {
			self.exposureView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
			self.poiOffset = CGPoint(x: t.x - self.exposureView.frame.origin.x,
															 y: t.y - self.exposureView.frame.origin.y)
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = poiOffset {
			// poi
			exposureView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			let point = previewLayer?.captureDevicePointConverted(fromLayerPoint: touch)
			do {
				try captureDevice?.lockForConfiguration()
				captureDevice?.exposurePointOfInterest = point!
				captureDevice?.exposureMode = .continuousAutoExposure
				lockBtn.setImage(UIImage(systemName: "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
				captureDevice?.unlockForConfiguration()
				
			} catch { }
			
		} else {
			// pb
			if activeBar == nil {
				activeBar = touch.x > view.frame.width/2 ? focusBar : exposureBar
				activeBar?.touchesBegan(touches, with: event)
			} else {
				activeBar?.touchesMoved(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeBar?.touchesEnded(touches, with: event)
		activeBar = nil; poiOffset = nil
		
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.exposureView.transform = CGAffineTransform(scaleX: 1, y: 1)
		}, completion: nil)
	}
	
	
	private func setLineGrid() {
		let v1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0,
																	width: 1, height: view.frame.height))
		let v2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0,
																	width: 1, height: view.frame.height))
		let h1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5,
																	width: view.frame.width, height: 1))
		let h2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5,
																	width: view.frame.width, height: 1))
		
		for line in [v1, v2, h1, h2] {
			line.alpha = 0.25
			line.backgroundColor = .white
			line.addShadow(1, 0.6)
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
		captureDevice = devices.first { $0.position == .back }
		
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice!)
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
	
	private func setButtons() {
		view.addSubview(shotBtn)
		NSLayoutConstraint.activate([
			shotBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			shotBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			shotBtn.widthAnchor.constraint(equalToConstant: 72.5),
			shotBtn.heightAnchor.constraint(equalToConstant: 70)
		])
		shotBtn.imageView!.addShadow(2.5, 0.3)
		shotBtn.addTarget(self, action: #selector(shotButtonTapped), for: .touchDown)
		
		let offset = view.frame.width/3
		
		view.addSubview(lightBtn)
		NSLayoutConstraint.activate([
			lightBtn.centerYAnchor.constraint(equalTo: shotBtn.centerYAnchor),
			lightBtn.widthAnchor.constraint(equalToConstant: 50),
			lightBtn.heightAnchor.constraint(equalToConstant: 50),
			lightBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		lightBtn.imageView!.addShadow(2.5, 0.3)
		lightBtn.addTarget(self, action: #selector(flashButtonTapped), for: .touchDown)
		
		view.addSubview(lockBtn)
		NSLayoutConstraint.activate([
			lockBtn.centerYAnchor.constraint(equalTo: shotBtn.centerYAnchor),
			lockBtn.widthAnchor.constraint(equalToConstant: 50),
			lockBtn.heightAnchor.constraint(equalToConstant: 50),
			lockBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
		lockBtn.imageView!.addShadow(2.5, 0.3)
		lockBtn.addTarget(self, action: #selector(lockButtonTapped), for: .touchDown)
	}
	
	private func setSliders() {
		exposureBar = VerticalProgressBar(frame: CGRect(x: 0, y: view.frame.midY, width: 55, height: 300), true, "sun.max.fill", "sun.min")
		exposureBar.valueChanged = exposureValueChanged
		exposureBar.alpha = 0
		view.addSubview(exposureBar)

		focusBar = VerticalProgressBar(frame: CGRect(x: view.frame.maxX, y: view.frame.midY, width: 55, height: 300), false, "plus.magnifyingglass", "minus.magnifyingglass")
		focusBar.valueChanged = focusValueChanged
		focusBar.alpha = 0
		view.addSubview(focusBar)
	}
	
	private func setPoint() {
		exposureView.addShadow(1, 0.125)
		view.addSubview(exposureView)
		guard let p = previewLayer?.layerPointConverted(fromCaptureDevicePoint: captureDevice!.exposurePointOfInterest) else { return }
		exposureView.center = p
		exposureView.alpha = 1
	}
}


extension ViewController {
	@objc private func shotButtonTapped() {
		let settings = AVCapturePhotoSettings()
		self.photoOutput?.capturePhoto(with: settings, delegate: self)
	}
	
	@objc private func lockButtonTapped() {
		do {
			UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
			let isContinuous = captureDevice?.exposureMode == .continuousAutoExposure
			
			lockBtn.setImage(UIImage(systemName: isContinuous ? "lock.fill" : "lock", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
			let transition = CATransition()
			transition.duration = 0.15
			transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			transition.type = CATransitionType.fade
			lockBtn.imageView?.layer.add(transition, forKey: nil)
			
			try captureDevice?.lockForConfiguration()
			captureDevice?.exposureMode = isContinuous ? .locked : .continuousAutoExposure
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func flashButtonTapped() {
		UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
		let active = captureDevice?.isTorchActive
		lightBtn.setImage(UIImage(systemName: active! ? "bolt.slash" : "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
		let transition = CATransition()
		transition.duration = 0.15
		transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		transition.type = CATransitionType.fade
		lightBtn.imageView?.layer.add(transition, forKey: nil)
		
		do {
			if captureDevice!.hasTorch {
				try captureDevice?.lockForConfiguration()
				captureDevice?.torchMode = captureDevice!.isTorchActive ? .off : .on
				captureDevice?.unlockForConfiguration()
			}
		} catch {}
	}
	
	private func exposureValueChanged() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setExposureTargetBias(Float(exposureBar!.indicatorValue), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	private func focusValueChanged() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: Float(focusBar!.indicatorValue), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
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
