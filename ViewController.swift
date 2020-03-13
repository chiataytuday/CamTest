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
	
	var redCircle: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.backgroundColor = .systemRed
		button.layer.cornerRadius = 25
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
	var videoFileOutput: AVCaptureMovieFileOutput?
	var filePath: URL?
	
	var isRecording: Bool = false
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
			captureDevice?.setFocusModeLocked(lensPosition: 0.8, completionHandler: nil)
			captureDevice?.setExposureTargetBias(-0.8, completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice!)
			captureSession?.addInput(deviceInput)
			videoFileOutput = AVCaptureMovieFileOutput()
			videoFileOutput?.movieFragmentInterval = CMTime.invalid
			captureSession?.addOutput(videoFileOutput!)
			videoFileOutput!.connection(with: .video)!.preferredVideoStabilizationMode = .cinematic
		} catch {}
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		filePath = documentsURL.appendingPathComponent("output.mov")
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer?.videoGravity = .resizeAspectFill
		previewLayer?.frame = view.frame
		previewLayer?.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer!, at: 0)
		
		captureSession?.startRunning()
	}
	
	private func setButtons() {
		let whiteCircle = UIButton()
		whiteCircle.translatesAutoresizingMaskIntoConstraints = false
		whiteCircle.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
		whiteCircle.layer.cornerRadius = 32.5
		whiteCircle.layer.borderColor = UIColor.white.cgColor
		whiteCircle.layer.borderWidth = 5
		whiteCircle.addShadow(2.5, 0.3)
		view.addSubview(whiteCircle)
		NSLayoutConstraint.activate([
			whiteCircle.widthAnchor.constraint(equalToConstant: 65),
			whiteCircle.heightAnchor.constraint(equalToConstant: 65),
			whiteCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			whiteCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35)
		])
		
		view.insertSubview(redCircle, belowSubview: whiteCircle)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 50),
			redCircle.heightAnchor.constraint(equalToConstant: 50),
			redCircle.centerXAnchor.constraint(equalTo: whiteCircle.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor)
		])
		whiteCircle.addTarget(self, action: #selector(shotTouchDown), for: .touchDown)
		whiteCircle.addTarget(self, action: #selector(shotTouchUp), for: .touchUpInside)
		whiteCircle.addTarget(self, action: #selector(shotTouchUp), for: .touchUpOutside)
		
		let offset = view.frame.width/3
		
		view.addSubview(lightBtn)
		NSLayoutConstraint.activate([
			lightBtn.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			lightBtn.widthAnchor.constraint(equalToConstant: 50),
			lightBtn.heightAnchor.constraint(equalToConstant: 50),
			lightBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		lightBtn.imageView!.addShadow(2.5, 0.3)
		lightBtn.addTarget(self, action: #selector(flashButtonTapped), for: .touchDown)
		
		view.addSubview(lockBtn)
		NSLayoutConstraint.activate([
			lockBtn.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			lockBtn.widthAnchor.constraint(equalToConstant: 50),
			lockBtn.heightAnchor.constraint(equalToConstant: 50),
			lockBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
		lockBtn.imageView!.addShadow(2.5, 0.3)
		lockBtn.addTarget(self, action: #selector(lockButtonTapped), for: .touchDown)
	}
	
	private func setSliders() {
		exposureBar = VerticalProgressBar(frame: CGRect(x: 0, y: view.frame.midY, width: 55, height: 250), true, "sun.max.fill", "sun.min")
		exposureBar.valueChanged = exposureValueChanged
		exposureBar.alpha = 0
		view.addSubview(exposureBar)
		exposureBar.setValue(-0.8)

		focusBar = VerticalProgressBar(frame: CGRect(x: view.frame.maxX, y: view.frame.midY, width: 55, height: 260), false, "plus.magnifyingglass", "minus.magnifyingglass")
		focusBar.valueChanged = focusValueChanged
		focusBar.alpha = 0
		view.addSubview(focusBar)
		focusBar.setValue(0.8)
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
	
	@objc private func shotTouchDown() {
		let scale: CGFloat = isRecording ? 0.45 : 0.9
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.redCircle.transform = CGAffineTransform(scaleX: scale, y: scale)
		}, completion: nil)
	}
	
	@objc private func shotTouchUp() {
		let scale: CGFloat = isRecording ? 1 : 0.55
		let radius: CGFloat = isRecording ? 25 : 10
		isRecording = !isRecording
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.redCircle.transform = CGAffineTransform(scaleX: scale, y: scale)
			self.redCircle.layer.cornerRadius = radius
		}, completion: nil)
	}
	
//	@objc private func shotButtonTapped() {
//		if !isRecording {
//			isRecording = true
//			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.1, options: .curveEaseOut, animations: {
//				self.redCircle.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
//				self.redCircle.layer.cornerRadius = 10
//			}, completion: nil)
//			let delegate: AVCaptureFileOutputRecordingDelegate = self
//			videoFileOutput!.startRecording(to: filePath!, recordingDelegate: delegate)
//
//		} else {
//			isRecording = false
//			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.1, options: .curveEaseIn, animations: {
//				self.redCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
//				self.redCircle.layer.cornerRadius = 25
//			}, completion: nil)
//			videoFileOutput?.stopRecording()
//		}
//	}
	
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
		UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
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

extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
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
