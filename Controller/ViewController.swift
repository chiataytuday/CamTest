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
	
	var captureSession: AVCaptureSession?
	var captureDevice: AVCaptureDevice?
	var previewLayer: AVCaptureVideoPreviewLayer?
	var videoFileOutput: AVCaptureMovieFileOutput?
	var filePath: URL?
	
	var whiteCircle: UIButton!
	
	private let redButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.isUserInteractionEnabled = false
		button.backgroundColor = .systemRed
		button.layer.cornerRadius = 10
		return button
	}()
	
	private let torchButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
		button.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
		button.backgroundColor = .black
		button.tintColor = .systemGray2
		button.layer.cornerRadius = 20
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}()
	
	private let lockButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
		button.setImage(UIImage(systemName: "lock.fill"), for: .normal)
		button.backgroundColor = .black
		button.tintColor = .systemGray2
		button.layer.cornerRadius = 20
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		
		return button
	}()
	
	private let exposurePointView: UIImageView = {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		return imageView
	}()
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .systemRed
		bar.layer.cornerRadius = 1
		return bar
	}()
	
	var isRecording: Bool = false
	var exposureSlider, focusSlider: Slider!
	var activeSlider: Slider?
	var touchOffset: CGPoint?
	var durationBarAnim: UIViewPropertyAnimator?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupCamera()
		setupUserInterface()
		setupGrid()
		setupSliders()
		setupExposurePoint()
		
		durationBar.frame.origin.y = view.frame.height - 0.5
		print(captureDevice?.exposureMode == .locked)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			exposurePointView.frame.contains(touch) else { return }

		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.touchOffset = CGPoint(x: touch.x - self.exposurePointView.frame.origin.x,
															 y: touch.y - self.exposurePointView.frame.origin.y)
			self.exposurePointView.alpha = 1
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			// Point of interest
			UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) {
				self.exposurePointView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			let point = previewLayer?.captureDevicePointConverted(fromLayerPoint: touch)
			let mode = captureDevice?.exposureMode
			do {
				try captureDevice?.lockForConfiguration()
				captureDevice?.exposureMode = .custom
				captureDevice?.exposurePointOfInterest = point!
				captureDevice?.exposureMode = mode!
				captureDevice?.unlockForConfiguration()
			} catch { }
			
		} else {
			// Progress bar
			if activeSlider == nil {
				activeSlider = touch.x > view.frame.width/2 ? focusSlider : exposureSlider
				activeSlider?.touchesBegan(touches, with: event)
			} else {
				activeSlider?.touchesMoved(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil; touchOffset = nil
		
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 1, y: 1)
//			self.poiView.alpha = 0.5
		}, completion: nil)
	}
}


extension ViewController {
	
	private func setupGrid() {
		let v1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0, width: 1, height: previewLayer!.frame.height))
		let v2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0, width: 1, height: previewLayer!.frame.height))
		let h1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5,	width: view.frame.width, height: 1))
		let h2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5, width: view.frame.width, height: 1))

		for line in [v1, v2, h1, h2] {
			line.alpha = 0.2
			line.backgroundColor = .white
			line.addShadow(1, 0.6)
			view.addSubview(line)
		}
	}
	
	private func setupCamera() {
		// Session
		captureSession = AVCaptureSession()
		captureSession?.sessionPreset = .hd4K3840x2160
		
		// Devices
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		captureDevice = devices.first { $0.position == .back }
		
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
			captureDevice?.setExposureTargetBias(-1, completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice!)
			captureSession?.addInput(deviceInput)
			
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			captureSession?.addInput(audioInput)
			
			videoFileOutput = AVCaptureMovieFileOutput()
			videoFileOutput?.movieFragmentInterval = CMTime.invalid
			captureSession?.addOutput(videoFileOutput!)
			videoFileOutput!.connection(with: .video)!.preferredVideoStabilizationMode = .cinematic
		} catch {}
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		filePath = documentsURL.appendingPathComponent("output").appendingPathExtension("mp4")
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer?.videoGravity = .resizeAspectFill
		previewLayer?.frame = view.frame
		previewLayer?.frame.size.height -= 100
		previewLayer?.cornerRadius = 20
		previewLayer?.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer!, at: 0)
		
		
		captureSession?.startRunning()
	}
	
	private func setupUserInterface() {
		// Recording
		whiteCircle = UIButton()
		whiteCircle.translatesAutoresizingMaskIntoConstraints = false
		whiteCircle.backgroundColor = .black
		whiteCircle.layer.cornerRadius = 20
		whiteCircle.layer.borderColor = UIColor.systemGray5.cgColor
		whiteCircle.layer.borderWidth = 1
		view.addSubview(whiteCircle)
		NSLayoutConstraint.activate([
			whiteCircle.widthAnchor.constraint(equalToConstant: 60),
			whiteCircle.heightAnchor.constraint(equalToConstant: 60),
			whiteCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			whiteCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
		])
		
		view.insertSubview(redButton, aboveSubview: whiteCircle)
		whiteCircle.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		whiteCircle.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		whiteCircle.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		NSLayoutConstraint.activate([
			redButton.widthAnchor.constraint(equalToConstant: 20),
			redButton.heightAnchor.constraint(equalToConstant: 20),
			redButton.centerXAnchor.constraint(equalTo: whiteCircle.centerXAnchor),
			redButton.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor)
		])
		
		// Light
		let offset: CGFloat = 80
		view.addSubview(torchButton)
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: [.touchDown])
		torchButton.addTarget(self, action: #selector(torchTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			torchButton.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			torchButton.widthAnchor.constraint(equalToConstant: 49),
			torchButton.heightAnchor.constraint(equalToConstant: 47.5),
			torchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		
		view.addSubview(lockButton)
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		lockButton.addTarget(self, action: #selector(lockTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			lockButton.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			lockButton.widthAnchor.constraint(equalToConstant: 49),
			lockButton.heightAnchor.constraint(equalToConstant: 47.5),
			lockButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
		
		view.addSubview(durationBar)
	}
	
	private func setupSliders() {
		let popup = Popup(CGPoint(x: view.center.x, y: 20))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 240), view.frame, .left)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureValue
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.customRange(-2, 2, -1)
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 240), view.frame, .right)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		focusSlider.customRange(0, 1, 0.5)
		focusSlider.setImage("globe")
		view.addSubview(focusSlider)
	}
	
	private func setupExposurePoint() {
		exposurePointView.center = view.center
		view.addSubview(exposurePointView)
	}
	
	
	@objc private func recordTouchDown() {
		redButton.transform = CGAffineTransform(rotationAngle: 0)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.whiteCircle.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.redButton.transform = CGAffineTransform(translationX: 0, y: 5).scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/4)
		}, completion: nil)
	}
	
	@objc private func recordTouchUp() {
		isRecording = !isRecording
		if isRecording {
			videoFileOutput!.startRecording(to: filePath!, recordingDelegate: self)
			durationBarAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: {
				self.durationBar.frame.size.width = self.view.frame.width
			})
			durationBarAnim?.addCompletion({ (_) in self.recordTouchUp() })
			durationBarAnim?.startAnimation()
			
		} else {
			videoFileOutput?.stopRecording()
			durationBarAnim?.stopAnimation(true)
			durationBarAnim = nil
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.durationBar.frame.size.width = 0
			}, completion: nil)
		}
		
		let radius: CGFloat = isRecording ? 3.5 : 10
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.whiteCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
			self.redButton.transform = CGAffineTransform(translationX: 0, y: 0).scaledBy(x: 1, y: 1)
			self.redButton.layer.cornerRadius = radius
		}, completion: nil)
	}
	
	@objc private func lockTouchDown() {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.lockButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.lockButton.imageView!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: -.pi/3)
		}, completion: nil)
	}
	
	@objc private func lockTouchUp() {
		let isLocked = captureDevice?.exposureMode == .locked
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.exposureMode = isLocked ? .continuousAutoExposure : .locked
			captureDevice?.unlockForConfiguration()
		} catch {}
		
		let args: (UIColor, UIColor) = isLocked ? (UIColor.black, UIColor.systemGray2) : (UIColor.systemGray2, UIColor.black)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.lockButton.transform = CGAffineTransform(scaleX: 1, y: 1)
			self.lockButton.backgroundColor = args.0
			self.lockButton.tintColor = args.1
			self.lockButton.layer.borderColor = isLocked ? UIColor.systemGray5.cgColor : UIColor.systemGray2.cgColor
			self.lockButton.imageView!.transform = CGAffineTransform(rotationAngle: 0)
		}, completion: nil)
	}
	
	@objc private func torchTouchDown() {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.torchButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.torchButton.imageView!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: .pi/4)
		}, completion: nil)
	}
	
	@objc private func torchTouchUp() {
		if captureDevice!.hasTorch {
			let torchEnabled = captureDevice!.isTorchActive
			do {
				try captureDevice?.lockForConfiguration()
				captureDevice?.torchMode = torchEnabled ? .off : .on
				captureDevice?.unlockForConfiguration()
			} catch {}
			let args: (UIColor, UIColor) = torchEnabled ? (UIColor.black, UIColor.systemGray2) : (UIColor.systemGray2, UIColor.black)
//			torchButton.backgroundColor = args.0
//			torchButton.tintColor = args.1
//			torchButton.layer.borderColor = torchEnabled ? UIColor.systemGray5.cgColor : UIColor.systemGray2.cgColor
			
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
				self.torchButton.transform = CGAffineTransform(scaleX: 1, y: 1)
				self.torchButton.backgroundColor = args.0
				self.torchButton.tintColor = args.1
				self.torchButton.layer.borderColor = torchEnabled ? UIColor.systemGray5.cgColor : UIColor.systemGray2.cgColor
				self.torchButton.imageView!.transform = CGAffineTransform(rotationAngle: 0)
				
			}, completion: nil)
		}
	}
	
	
	private func updateExposureValue() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setExposureTargetBias(Float(exposureSlider.value), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	private func updateLensPosition() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: Float(focusSlider.value), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		let playerController = PlayerController()
		playerController.url = outputFileURL
		playerController.modalPresentationStyle = .overFullScreen
		present(playerController, animated: true)
		
//		UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
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
