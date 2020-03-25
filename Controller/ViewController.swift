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

class Colors {
	static let sliderRange = colorByRGB(34, 34, 34)
	static let sliderIcon = colorByRGB(95, 95, 95)
	static let popupContent = colorByRGB(132, 132, 132)
	static let disabledButton = colorByRGB(45, 45, 45)
	static let enabledButton = colorByRGB(142, 142, 142)
	static let recordButtonDown = colorByRGB(20, 20, 20)
	static let recordButtonUp = colorByRGB(30, 30, 30)
	static let red = colorByRGB(205, 52, 41)
	static let yellow = colorByRGB(254, 199, 32)
	static let exportLabel = colorByRGB(140, 140, 140)
	static let backIcon = colorByRGB(72, 72, 72)
	static let permissionIcon = colorByRGB(100, 100, 100)
	static let permissionBorder = colorByRGB(45, 45, 45)
	static let permissionBackground = colorByRGB(12, 12, 12)
	
	private static func colorByRGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
		return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
	}
}

class Settings {
	var torchEnabled = false
	var playerOpened = false
	var exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
	
	static let shared = Settings()
}

class ViewController: UIViewController {
	
	var cam: Camera!
	
	var isRecording = false
	var exposureSlider, focusSlider: Slider!
	var activeSlider: Slider?
	var touchOffset: CGPoint?
	var durationAnim: UIViewPropertyAnimator?
	var recordingTimer: Timer?

	
	let blurView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: .regular)
		let effectView = UIVisualEffectView(effect: effect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	private let exposurePointView: UIImageView = {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = Colors.yellow
		return imageView
	}()
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 2))
		bar.backgroundColor = Colors.red
		bar.layer.cornerRadius = 0.25
		return bar
	}()
	
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
		view.backgroundColor = Colors.red
		view.layer.cornerRadius = 10
		return view
	}()
	
	var playerController: PlayerController!
	private var lockButton, torchButton: UIButton!
	var stackView: UIStackView!
	
	
	// MARK: - Touch functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black
		
		cam = Camera()
		cam.attachLayer(to: view)
		
		setupSecondary()
		setupBottomButtons()
		setupSliders()
		attachActions()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		exposurePointView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
		UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform.identity
		})
	}
	
	override func viewDidLayoutSubviews() {
		stackView.arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18.5)
		stackView.arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18.5)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			exposurePointView.frame.contains(touch) else { return }
		
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		})
		touchOffset = CGPoint(x: touch.x - exposurePointView.frame.origin.x, y: touch.y - exposurePointView.frame.origin.y)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.exposurePointView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			cam.setExposure(touch, .autoExpose)
			
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
		
		var pointOfInterest: CGPoint?
		if let _ = touchOffset, exposurePointView.frame.maxY > view.frame.height - 80 {
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.25, options: .curveEaseOut, animations: {
				self.exposurePointView.center.y = self.view.frame.height - 80 - self.exposurePointView.frame.height/2
			})
			pointOfInterest = exposurePointView.center
		}
		
		touchOffset = nil
		if let point = pointOfInterest {
			cam.setExposure(point, Settings.shared.exposureMode)
		} else {
			cam.setExposure(Settings.shared.exposureMode)
		}
		
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform.identity
		})
	}
}


extension ViewController {
	
	private func setupBottomButtons() {
		lockButton = menuButton("lock.fill")
		torchButton = menuButton("bolt.fill")
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
	
	private func setupSliders() {
		let popup = Popup(CGPoint(x: view.center.x, y: 20))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 280), view.frame, .left)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.customRange(-3, 3, -0.5)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureTargetBias
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 280), view.frame, .right)
		focusSlider.setImage("globe")
		focusSlider.customRange(0, 1, 0.4)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		view.addSubview(focusSlider)
	}
	
	private func setupSecondary() {
		// MARK:- Grid
		let v1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0, width: 1, height: view.frame.height))
		let v2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0, width: 1, height: view.frame.height))
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
		
		// MARK:- Exposure point & blur
		exposurePointView.center = view.center
		view.addSubview(exposurePointView)
		
		blurView.frame = view.bounds
		view.insertSubview(blurView, belowSubview: exposurePointView)
	}
	
	private func attachActions() {
		for button in [lockButton, torchButton] {
			button!.addTarget(self, action: #selector(menuButtonTouchDown(sender:)), for: .touchDown)
		}
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: .touchDown)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
	}
	
	
	@objc private func didEnterBackground() {
		cam.stopSession()
		if Settings.shared.playerOpened {
			playerController.queuePlayer.pause()
		} else if isRecording {
			recordTouchUp()
		}
	}
	
	@objc private func didBecomeActive() {
		cam.startSession()
		if Settings.shared.playerOpened {
			playerController.queuePlayer.play()
		} else if !Settings.shared.playerOpened && Settings.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	public func resetControls() {
		view.isUserInteractionEnabled = true
	}
	
	// MARK: - TouchUp & TouchDown
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
			self.recordButton.backgroundColor = Colors.recordButtonDown
		})
	}
	
	@objc private func recordTouchUp() {
		isRecording = !isRecording
		if isRecording {
			cam.startRecording(self)
			recordButton.backgroundColor = Colors.recordButtonUp
			durationAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: {
				self.durationBar.frame.size.width = self.view.frame.width
			})
			durationAnim?.addCompletion({ (_) in self.recordTouchUp() })
			durationAnim?.startAnimation()
			
		} else {
			cam.stopRecording()
			recordingTimer?.invalidate()
			durationAnim?.stopAnimation(true)
			durationAnim = nil
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.durationBar.frame.size.width = 0
			})
		}
		
		let radius: CGFloat = isRecording ? 3.5 : 10
		let color: UIColor = isRecording ? Colors.recordButtonUp : .black
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = radius
			if !self.isRecording {
				self.recordButton.backgroundColor = color
			}
		})
	}
	
	@objc private func lockTouchDown() {
		let isLocked = cam.device.exposureMode == .locked
		let mode: AVCaptureDevice.ExposureMode = isLocked ? .continuousAutoExposure : .locked
		Settings.shared.exposureMode = mode
		cam.setExposure(mode)
	}
	
	@objc private func menuButtonTouchDown(sender: UIButton) {
		if sender.tag == 0 {
			sender.tintColor = Colors.enabledButton
			sender.tag = 1
		} else {
			sender.tintColor = Colors.disabledButton
			sender.tag = 0
		}
		
		sender.imageView?.transform = CGAffineTransform(rotationAngle: .pi/4)
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [.curveLinear, .allowUserInteraction], animations: {
			sender.imageView?.transform = CGAffineTransform.identity
		})
	}
	
	@objc private func torchTouchDown() {
		let torchEnabled = cam.device.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		Settings.shared.torchEnabled = !torchEnabled
		cam.setTorch(mode)
	}
	
	// MARK: - Secondary
	
	private func updateExposureTargetBias() {
		cam.setTargetBias(Float(exposureSlider.value))
	}
	
	private func updateLensPosition() {
		cam.setLensPosition(Float(focusSlider.value))
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	private func menuButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.backgroundColor = .black
		button.tintColor = Colors.disabledButton
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}
}


extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		if output.recordedDuration.seconds > 0.25 {
			view.isUserInteractionEnabled = false
			UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
				self.blurView.alpha = 1
			})
			
			playerController = PlayerController()
			if Settings.shared.torchEnabled {
				cam.setTorch(.off)
			}
			playerController.setupPlayer(outputFileURL) { [weak self] (ready) in
				guard let vc = self else { return }
				if ready {
					Settings.shared.playerOpened = true
					vc.present(vc.playerController, animated: true)
				} else {
					vc.resetControls()
					UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
						vc.blurView.alpha = 0
					})
					let error = Notification("Something went wrong", CGPoint(x: vc.view.center.x, y: vc.view.frame.height - 130))
					vc.view.addSubview(error)
					error.animate()
				}
			}
		}
		
//		if duration > 0.25 {
//			view.isUserInteractionEnabled = false
//			UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
//				self.blurView.alpha = 1
//			})
//		}
		
		
//		if output.recordedDuration.seconds > 0.25 {
//			playerController = PlayerController()
//			if Settings.shared.torchEnabled {
//				cam.setTorch(.off)
//			}
//
//			playerController.setupPlayer(outputFileURL) { (fileLoaded) in
//				if fileLoaded {
//					self.playerController.modalPresentationStyle = .overFullScreen
//					Settings.shared.playerOpened = true
//					self.present(self.playerController, animated: true)
//				} else {
//					self.resetControls()
//					UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
//						self.blurView.alpha = 0
//					})
//					let error = Notification("Something went wrong", CGPoint(x: self.view.center.x, y: self.view.frame.height - 130))
//					self.view.addSubview(error)
//					error.animate()
//				}
//			}
//		}
	}
}
