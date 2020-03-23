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
	
	var isRecording = false
	var exposureSlider, focusSlider: Slider!
	var activeSlider: Slider?
	var touchOffset: CGPoint?
	var durationBarAnim: UIViewPropertyAnimator?
	private var recordingTimer: Timer?
	
	let blurEffectView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
		let effectView = UIVisualEffectView(effect: blurEffect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	var captureSession: AVCaptureSession!
	var captureDevice: AVCaptureDevice!
	var previewLayer: AVCaptureVideoPreviewLayer!
	var videoFileOutput: AVCaptureMovieFileOutput!
	var filePath: URL!
	
	
	private let recordButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.backgroundColor = .black
		return button
	}()
	
	private let redCircle: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isUserInteractionEnabled = false
		view.backgroundColor = .systemRed
		view.layer.cornerRadius = 10
		return view
	}()
	
	private var exposureButton, lockButton, torchButton, lensButton: UIButton!
	var stackView: UIStackView!
	
	let exposurePointView: UIImageView = {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		return imageView
	}()
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
		bar.backgroundColor = .systemRed
		bar.layer.cornerRadius = 0.25
		return bar
	}()
	
	private let overlayView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		view.alpha = 0
		return view
	}()
	
	// MARK: - Touch functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupCamera()
		setupGrid()
		layoutBottomBar()
		attachBottomBarTargets()
		setupControls()
		
//		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
//			self.overlayView.alpha = 0
//			self.blurEffectView.alpha = 0
//		}, completion: nil)
	}
	
	override func viewDidLayoutSubviews() {
		stackView.arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18.5)
		stackView.arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18.5)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			exposurePointView.frame.contains(touch) else { return }
		do {
			try captureDevice.lockForConfiguration()
		} catch {}

		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.touchOffset = CGPoint(x: touch.x - self.exposurePointView.frame.origin.x,
															 y: touch.y - self.exposurePointView.frame.origin.y)
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.exposurePointView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			let point = previewLayer.captureDevicePointConverted(fromLayerPoint: touch)
			let mode = captureDevice.exposureMode
			captureDevice.exposureMode = .custom
			captureDevice.exposurePointOfInterest = point
			captureDevice.exposureMode = mode
		} else {
			if let slider = activeSlider {
				slider.touchesMoved(touches, with: event)
			} else {
				activeSlider = touch.x > view.frame.width/2 ? focusSlider : exposureSlider
				do {
					try captureDevice.lockForConfiguration()
				} catch {}
				activeSlider?.touchesBegan(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil
		
		if let _ = touchOffset, exposurePointView.frame.maxY > view.frame.height - 100 {
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.25, options: .curveEaseOut, animations: {
				self.exposurePointView.center.y = self.view.frame.height - 81.5 - self.exposurePointView.frame.height/2
			}, completion: nil)
			let point = previewLayer.captureDevicePointConverted(fromLayerPoint: exposurePointView.center)
			let mode = captureDevice.exposureMode
			captureDevice.exposureMode = .custom
			captureDevice.exposurePointOfInterest = point
			captureDevice.exposureMode = mode
		}
		captureDevice.unlockForConfiguration()
		touchOffset = nil
		
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform.identity
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
			line.layer.shadowColor = UIColor.black.cgColor
			line.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
			line.layer.shadowOpacity = 0.6
			line.layer.shadowRadius = 1
			line.clipsToBounds = false
			view.addSubview(line)
		}
	}
	
	private func setupCamera() {
		// Session
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = .hd1920x1080
		
		// Devices
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		captureDevice = devices.first { $0.position == .back }
		
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setFocusModeLocked(lensPosition: 0.3, completionHandler: nil)
			captureDevice.setExposureTargetBias(-0.5, completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
			captureSession.addInput(deviceInput)
			
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			captureSession.addInput(audioInput)
			
			videoFileOutput = AVCaptureMovieFileOutput()
			videoFileOutput.movieFragmentInterval = CMTime.invalid
			captureSession.addOutput(videoFileOutput)
			videoFileOutput.connection(with: .video)?.preferredVideoStabilizationMode = .cinematic
		} catch {}
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		filePath = documentsURL.appendingPathComponent("output").appendingPathExtension("mp4")
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.frame = view.frame
		previewLayer.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer, at: 0)
		
		captureSession.startRunning()
	}
	
	private func attachBottomBarTargets() {
		for button in [exposureButton, lockButton, torchButton, lensButton] {
			button!.addTarget(self, action: #selector(secondaryTouchDown(sender:)), for: .touchDown)
		}
		
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: .touchDown)
	}
	
	private func layoutBottomBar() {
		exposureButton = secondaryMenuButton("sun.max.fill")
		lockButton = secondaryMenuButton("lock.fill")
		torchButton = secondaryMenuButton("bolt.fill")
		lensButton = secondaryMenuButton("globe")

		let buttons: [UIButton] = [torchButton, recordButton, lockButton]
		for button in buttons {
			NSLayoutConstraint.activate([
				button.widthAnchor.constraint(equalToConstant: 57.5),
				button.heightAnchor.constraint(equalToConstant: 55)
			])
		}
		stackView = UIStackView(arrangedSubviews: buttons)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.distribution = .fillProportionally
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		view.insertSubview(redCircle, aboveSubview: recordButton)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 20),
			redCircle.heightAnchor.constraint(equalToConstant: 20),
			redCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
		])

		view.addSubview(durationBar)
		durationBar.frame.origin.y = view.frame.height - durationBar.frame.height
	}
	
	public func resetControls() {
		lockButton.transform = CGAffineTransform.identity
		lockButton.alpha = 1
		recordButton.isUserInteractionEnabled = true
	}
	
	private func setupControls() {
		let popup = Popup(CGPoint(x: view.center.x, y: 20))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 320), view.frame, .left)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.customRange(-4, 4, -0.5)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureValue
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 320), view.frame, .right)
		focusSlider.setImage("globe")
		focusSlider.customRange(0, 1, 0.3)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		view.addSubview(focusSlider)
		
		exposurePointView.center = view.center
		view.addSubview(exposurePointView)
		
		overlayView.frame = view.frame
		view.insertSubview(overlayView, belowSubview: exposurePointView)
		
    blurEffectView.frame = view.bounds
		view.insertSubview(blurEffectView, belowSubview: exposurePointView)
	}
	
	// MARK: - TouchUp & TouchDown
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
			self.recordButton.backgroundColor = UIColor(white: 0.075, alpha: 1)
		}, completion: nil)
	}
	
	@objc private func recordTouchUp() {
		isRecording = !isRecording
		if isRecording {
			videoFileOutput!.startRecording(to: filePath!, recordingDelegate: self)
			self.recordButton.backgroundColor = .systemGray6
			durationBarAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: {
				self.durationBar.frame.size.width = self.view.frame.width
			})
			durationBarAnim?.addCompletion({ (_) in self.recordTouchUp() })
			durationBarAnim?.startAnimation()
			
		} else {
			videoFileOutput.stopRecording()
			recordingTimer?.invalidate()
			durationBarAnim?.stopAnimation(true)
			durationBarAnim = nil
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.durationBar.frame.size.width = 0
			}, completion: nil)
			
			if videoFileOutput.recordedDuration.seconds > 0.25 {
				recordButton.isUserInteractionEnabled = false
				UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
					self.blurEffectView.alpha = 1
				}, completion: nil)
			}
		}
		
		let radius: CGFloat = isRecording ? 3.5 : 10
		let color: UIColor = isRecording ? .systemGray6 : .black
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = radius
			if !self.isRecording {
				self.recordButton.backgroundColor = color
			}
		}, completion: nil)
	}
	
	@objc private func lockTouchDown() {
		let isLocked = captureDevice.exposureMode == .locked
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.exposureMode = isLocked ? .continuousAutoExposure : .locked
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	@objc private func secondaryTouchDown(sender: UIButton) {
		if sender.tag == 0 {
			sender.tintColor = .systemGray
			sender.tag = 1
		} else {
			sender.tintColor = .systemGray5
			sender.tag = 0
		}
		
		sender.imageView?.transform = CGAffineTransform(rotationAngle: .pi/3)
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveLinear, .allowUserInteraction], animations: {
			sender.imageView?.transform = CGAffineTransform.identity
		}, completion: nil)
	}
	
	@objc private func torchTouchDown() {
		guard captureDevice.hasTorch else { return }
		let torchEnabled = captureDevice.isTorchActive
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.torchMode = torchEnabled ? .off : .on
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	// MARK: - Secondary
	
	private func updateExposureValue() {
		captureDevice.setExposureTargetBias(Float(exposureSlider.value), completionHandler: nil)
	}
	
	private func updateLensPosition() {
		captureDevice.setFocusModeLocked(lensPosition: Float(focusSlider.value), completionHandler: nil)
	}
	
	private func secondaryMenuButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.backgroundColor = .black
		button.tintColor = .systemGray5
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		if videoFileOutput.recordedDuration.seconds > 0.25 {
			let playerController = PlayerController()
			playerController.torchWasEnabled = captureDevice.isTorchActive
			if captureDevice.isTorchActive {
				do {
					try captureDevice.lockForConfiguration()
					captureDevice.torchMode = .off
					captureDevice.unlockForConfiguration()
				} catch {}
			}
			
			playerController.setupPlayer(outputFileURL) {
				playerController.modalPresentationStyle = .overFullScreen
				self.present(playerController, animated: true)
			}
		}
	}
}
