//
//  CameraController.swift
//  CamTest
//
//  Created by debavlad on 07.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class CameraController: UIViewController {
	
	private var cam: Camera!
	private var exposureSlider, lensSlider: VerticalSlider!
	private var exposurePointView: MovablePoint!
	private var activeSlider: VerticalSlider?
	
	let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: .regular)
		let effectView = UIVisualEffectView(effect: effect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	private let redCircle: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isUserInteractionEnabled = false
		view.backgroundColor = Colors.red
		view.layer.cornerRadius = 10
		return view
	}()
	
	private var playerController: PlayerController?
	private var torchButton, recordButton, lockButton: SquareButton!
	private var btnStackView: UIStackView!
	
	deinit {
		print("Why the fuck would you do that")
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black
		
		cam = Camera()
		cam.attach(to: view)
		setupBottomButtons()
		attachActions()
		setupVerticalSliders()
		setupSecondary()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: view).x
		activeSlider = touchX > view.frame.width/2 ? lensSlider : exposureSlider
		activeSlider?.touchesBegan(touches, with: event)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesMoved(touches, with: event)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
}


extension CameraController {
	
	override func viewDidLayoutSubviews() {
		btnStackView.arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 16)
		btnStackView.arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 16)
	}
	
	private func setupBottomButtons() {
		torchButton = SquareButton("bolt.fill")
		lockButton = SquareButton("lock.fill")
		recordButton = SquareButton(nil)
		view.addSubview(recordButton)
		NSLayoutConstraint.activate([
			recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		btnStackView = UIStackView(arrangedSubviews: [torchButton, lockButton])
		btnStackView.translatesAutoresizingMaskIntoConstraints = false
		btnStackView.distribution = .fillProportionally
		view.addSubview(btnStackView)
		let xOffset = (view.frame.width/2 - 31.25)/2
		NSLayoutConstraint.activate([
			btnStackView.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
			btnStackView.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: xOffset)
		])
		
		view.insertSubview(redCircle, aboveSubview: recordButton)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 20),
			redCircle.heightAnchor.constraint(equalToConstant: 20),
			redCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
		])
	}
	
	private func setupVerticalSliders() {
		let popup = Popup()
		let popupY = UIApplication.shared.windows[0].safeAreaInsets.top + 25
		popup.center = CGPoint(x: view.center.x, y: popupY)
		view.addSubview(popup)
		
		exposureSlider = VerticalSlider(CGSize(width: 40, height: 280), view.frame, .left)
		exposureSlider.set(min: -3, max: 3, value: -0.5)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.delegate = updateTargetBias
		exposureSlider.popup = popup
		view.addSubview(exposureSlider)
		
		lensSlider = VerticalSlider(CGSize(width: 40, height: 280), view.frame, .right)
		lensSlider.set(min: 0, max: 1, value: 0.4)
		lensSlider.setImage("globe")
		lensSlider.delegate = updateLensPosition
		lensSlider.popup = popup
		view.addSubview(lensSlider)
	}
	
	private func setupSecondary() {
		exposurePointView = MovablePoint()
		exposurePointView.center = view.center
		exposurePointView.camera = cam
		view.addSubview(exposurePointView)
		
		blurEffectView.frame = view.bounds
		view.insertSubview(blurEffectView, belowSubview: exposurePointView)
	}
	
	private func attachActions() {
		for button in [lockButton, torchButton] {
			button!.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
		}
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: .touchDown)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
	}
	
	// MARK: - Buttons' handlers
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
		})
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.25)
	}
	
	@objc private func recordTouchUp() {
		if !cam.isRecording {
			cam.startRecording(self)
			cam.durationAnim?.addCompletion({ [unowned self] _ in
				self.recordTouchUp()
			})
			cam.durationAnim?.startAnimation()
			UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
				self.btnStackView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
				self.btnStackView.alpha = 0
			})
		} else {
			cam.stopRecording()
			if cam.output.recordedDuration.seconds > 0.25 {
				view.isUserInteractionEnabled = false
			}
		}
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.35)
		
		let radius: CGFloat = cam.isRecording ? 3.25 : 10
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = radius
		})
	}
	
	@objc private func lockTouchDown() {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		let isLocked = cam.device.exposureMode == .locked
		let mode: AVCaptureDevice.ExposureMode = isLocked ? .continuousAutoExposure : .locked
		User.shared.exposureMode = mode
		cam.setExposure(mode)
	}
	
	@objc private func buttonTouchDown(sender: UIButton) {
		// We shouldn't apply this in SquareButton class
		sender.imageView?.contentMode = .center
		// because buttons' images of LaunchScreen are inaccessible, so they differ
		
		if sender.tag == 0 {
			sender.tintColor = Colors.gray5
			sender.backgroundColor = Colors.gray1
			sender.tag = 1
		} else {
			sender.tintColor = Colors.gray3
			sender.backgroundColor = .black
			sender.tag = 0
		}
		
		sender.imageView?.transform = CGAffineTransform(rotationAngle: .pi/4)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [.curveLinear, .allowUserInteraction], animations: {
			sender.imageView?.transform = CGAffineTransform.identity
		})
	}
	
	@objc private func torchTouchDown() {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		let torchEnabled = cam.device.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		User.shared.torchEnabled = !torchEnabled
		cam.setTorch(mode)
	}
	
	// MARK: - Sliders handlers & Secondary methods
	
	private func updateTargetBias() {
		cam.setTargetBias(Float(exposureSlider.value))
	}
	
	private func updateLensPosition() {
		cam.setLensPosition(Float(lensSlider.value))
	}
	
	@objc private func didEnterBackground() {
		if let vc = presentedViewController as? PlayerController {
			vc.player.pause()
		} else if cam.isRecording {
			recordTouchUp()
		}
		cam.stopSession()
	}
	
	@objc private func didBecomeActive() {
		cam.startSession()
		if let vc = presentedViewController as? PlayerController {
			vc.player.play()
		} else if User.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	func resetView(_ transitionDuration: Double = 0) {
		view.isUserInteractionEnabled = true
		if User.shared.torchEnabled {
			cam.setTorch(.on)
		}
		touchesEnded(Set<UITouch>(), with: nil)
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.btnStackView.transform = .identity
			self.btnStackView.alpha = 1
		})
		playerController = nil
	}
}


extension CameraController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		guard output.recordedDuration.seconds > 0.25 else { return }
		playerController = PlayerController()
		playerController?.modalPresentationStyle = .overFullScreen
		playerController?.setupPlayer(outputFileURL) { [weak self, weak playerController] (ready) in
			if ready {
				self?.present(playerController!, animated: true, completion: { [weak self] in
					if User.shared.torchEnabled {
						self?.cam.setTorch(.off)
					}
				})
			} else {
				self?.resetView()
				let error = Notification(text: "Something went wrong")
				error.center = CGPoint(x: self!.view.center.x, y: self!.view.frame.height - 130)
				self?.view.addSubview(error)
				error.show()
			}
		}
	}
}
