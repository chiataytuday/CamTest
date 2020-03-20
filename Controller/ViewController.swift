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
		button.layer.cornerRadius = 20
		button.layer.borderColor = UIColor.systemGray5.cgColor
		button.layer.borderWidth = 1
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
	
	private var torchButton, lockButton: UIButton!
	
	let exposurePointView: UIImageView = {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		return imageView
	}()
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .systemRed
		bar.layer.cornerRadius = 0.25
		return bar
	}()
	
	private let timerLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "'15"
		label.font = UIFont.systemFont(ofSize: 16, weight: .light)
		label.textColor = .systemGray3
		label.alpha = 0
		return label
	}()
	
	// MARK: - Touch functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupCamera()
		setupBottomMenu()
		setupGrid()
		setupControls()
		
    blurEffectView.frame = view.bounds
    view.addSubview(blurEffectView)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			exposurePointView.frame.contains(touch) else { return }

		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.touchOffset = CGPoint(x: touch.x - self.exposurePointView.frame.origin.x,
															 y: touch.y - self.exposurePointView.frame.origin.y)
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) {
				self.exposurePointView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			let point = previewLayer.captureDevicePointConverted(fromLayerPoint: touch)
			let mode = captureDevice.exposureMode
			do {
				try captureDevice.lockForConfiguration()
				captureDevice.exposureMode = .custom
				captureDevice.exposurePointOfInterest = point
				captureDevice.exposureMode = mode
				captureDevice.unlockForConfiguration()
			} catch {}
			
		} else {
			if let slider = activeSlider {
				slider.touchesMoved(touches, with: event)
			} else {
				activeSlider = touch.x > view.frame.width/2 ? focusSlider : exposureSlider
				activeSlider?.touchesBegan(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil
		
		if let _ = touchOffset, exposurePointView.frame.maxY > view.frame.height - 100 {
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
				self.exposurePointView.center.y = self.view.frame.height - 100 - self.exposurePointView.frame.height/2
			}, completion: nil)
			let point = previewLayer.captureDevicePointConverted(fromLayerPoint: exposurePointView.center)
			let mode = captureDevice.exposureMode
			do {
				try captureDevice.lockForConfiguration()
				captureDevice.exposureMode = .custom
				captureDevice.exposurePointOfInterest = point
				captureDevice.exposureMode = mode
				captureDevice.unlockForConfiguration()
			} catch {}
		}
		touchOffset = nil
		
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
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
			captureDevice.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
			captureDevice.setExposureTargetBias(-1, completionHandler: nil)
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
		previewLayer.frame.size.height -= 100
		previewLayer.cornerRadius = 17.5
		previewLayer.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer, at: 0)
		
		captureSession.startRunning()
		
		print(exposurePointView.frame.size)
	}
	
	private func setupBottomMenu() {
		view.addSubview(recordButton)
		NSLayoutConstraint.activate([
			recordButton.widthAnchor.constraint(equalToConstant: 60),
			recordButton.heightAnchor.constraint(equalToConstant: 60),
			recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
		])
		
		view.insertSubview(redCircle, aboveSubview: recordButton)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 20),
			redCircle.heightAnchor.constraint(equalToConstant: 20),
			redCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
		])
		recordButton.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		
		
		let offset: CGFloat = 80
		torchButton = secondaryMenuButton("bolt.fill")
		view.addSubview(torchButton)
		NSLayoutConstraint.activate([
			torchButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
			torchButton.widthAnchor.constraint(equalToConstant: 49),
			torchButton.heightAnchor.constraint(equalToConstant: 47.5),
			torchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: [.touchDown])
		torchButton.addTarget(self, action: #selector(torchTouchUp), for: [.touchUpInside, .touchUpOutside])
		
		lockButton = secondaryMenuButton("lock.fill")
		view.addSubview(lockButton)
		NSLayoutConstraint.activate([
			lockButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
			lockButton.widthAnchor.constraint(equalToConstant: 49),
			lockButton.heightAnchor.constraint(equalToConstant: 47.5),
			lockButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		lockButton.addTarget(self, action: #selector(lockTouchUp), for: [.touchUpInside, .touchUpOutside])
		
		view.addSubview(timerLabel)
		NSLayoutConstraint.activate([
			timerLabel.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
			timerLabel.centerXAnchor.constraint(equalTo: lockButton.centerXAnchor, constant: -offset/1.25)
		])
		
		view.addSubview(durationBar)
		durationBar.frame.origin.y = view.frame.height - 0.5
	}
	
	public func resetControls() {
		lockButton.transform = CGAffineTransform.identity
		lockButton.alpha = 1
		recordButton.isUserInteractionEnabled = true
	}
	
	private func setupControls() {
		let popup = Popup(CGPoint(x: view.center.x, y: 20))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 240), view.frame, .left)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.customRange(-4, 4, -1)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureValue
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 240), view.frame, .right)
		focusSlider.setImage("globe")
		focusSlider.customRange(0, 1, 0.5)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		view.addSubview(focusSlider)
		
		exposurePointView.center = view.center
		view.addSubview(exposurePointView)
		print(exposurePointView.frame)
	}
	
	// MARK: - TouchUp & TouchDown
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.recordButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
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
			timerLabel.transform = CGAffineTransform(translationX: 5, y: 0)
			UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
				self.timerLabel.alpha = 1
				self.timerLabel.transform = CGAffineTransform.identity
			}, completion: nil)
			
			var sec = 15
			recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
				if sec == 0 {
					timer.invalidate()
				}
				sec -= 1
				self.timerLabel.text = "'\(sec)"
			}
			
		} else {
			videoFileOutput.stopRecording()
			recordingTimer?.invalidate()
			durationBarAnim?.stopAnimation(true)
			recordButton.isUserInteractionEnabled = false
			durationBarAnim = nil
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.durationBar.frame.size.width = 0
			}, completion: nil)
			UIView.animate(withDuration: 0.4, delay: 0.12, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.timerLabel.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
				self.timerLabel.alpha = 0
			}, completion: nil)
			UIView.animate(withDuration: 0.4, delay: 0.24, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.lockButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
				self.lockButton.alpha = 0
			}, completion: nil)
			UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
				self.blurEffectView.alpha = 1
			}, completion: nil)
		}
		
		let radius: CGFloat = isRecording ? 3.5 : 10
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 1.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.recordButton.transform = CGAffineTransform.identity
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = radius
		}, completion: nil)
	}
	
	@objc private func lockTouchDown() {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.lockButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.lockButton.imageView!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: -.pi/3)
		}, completion: nil)
	}
	
	@objc private func lockTouchUp() {
		let isLocked = captureDevice.exposureMode == .locked
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.exposureMode = isLocked ? .continuousAutoExposure : .locked
			captureDevice.unlockForConfiguration()
		} catch {}
		
		let args: (UIColor, UIColor) = isLocked ? (.black, .systemGray) : (.systemGray, .black)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.lockButton.transform = CGAffineTransform.identity
			self.lockButton.imageView!.transform = CGAffineTransform.identity
			self.lockButton.layer.borderColor = isLocked ? UIColor.systemGray5.cgColor : UIColor.systemGray.cgColor
			self.lockButton.backgroundColor = args.0
			self.lockButton.tintColor = args.1
		}, completion: nil)
	}
	
	@objc private func torchTouchDown() {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.torchButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.torchButton.imageView!.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: .pi/4)
		}, completion: nil)
	}
	
	@objc private func torchTouchUp() {
		guard captureDevice.hasTorch else { return }
		let torchEnabled = captureDevice.isTorchActive
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.torchMode = torchEnabled ? .off : .on
			captureDevice.unlockForConfiguration()
		} catch {}
		
		let args: (UIColor, UIColor) = torchEnabled ? (.black, .systemGray2) : (.systemGray2, .black)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.torchButton.transform = CGAffineTransform.identity
			self.torchButton.imageView!.transform = CGAffineTransform.identity
			self.torchButton.layer.borderColor = torchEnabled ? UIColor.systemGray5.cgColor : UIColor.systemGray2.cgColor
			self.torchButton.backgroundColor = args.0
			self.torchButton.tintColor = args.1
		}, completion: nil)
	}
	
	// MARK: - Secondary
	
	private func updateExposureValue() {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setExposureTargetBias(Float(exposureSlider.value), completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	private func updateLensPosition() {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setFocusModeLocked(lensPosition: Float(focusSlider.value), completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	private func secondaryMenuButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.backgroundColor = .black
		button.tintColor = .systemGray
		button.layer.cornerRadius = 20
		button.layer.borderWidth = 1
		button.layer.borderColor = UIColor.systemGray5.cgColor
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
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.torchMode = .off
			captureDevice.unlockForConfiguration()
		} catch {}
		
		let playerController = PlayerController()
		playerController.setupPlayer(outputFileURL) {
			playerController.modalPresentationStyle = .overFullScreen
			self.present(playerController, animated: true)
		}
	}
}
