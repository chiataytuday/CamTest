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
	
	private var cam: Camera!
	private var exposureSlider, focusSlider: Slider!
	private var exposurePointView: MovablePoint!
	private var activeSlider: Slider?
	
	private let blurView: UIVisualEffectView = {
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
		view.backgroundColor = .systemRed
		view.layer.cornerRadius = 10
		return view
	}()
	
	private var playerController: PlayerController?
	private var torchButton, recordButton, lockButton: MenuButton!
	private var stackView: UIStackView!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black
		
		cam = Camera()
		cam.attach(to: view)
		
		setupGrid()
		setupBottomMenu()
		attachActions()
		setupSliders()
		setupSecondary()
	}
	
	override func viewDidLayoutSubviews() {
		stackView.arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18.5)
		stackView.arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18.5)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first!.location(in: view)
		activeSlider = touch.x > view.frame.width/2 ? focusSlider : exposureSlider
		activeSlider?.touchesBegan(touches, with: event)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesMoved(touches, with: event)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil
	}
}


extension ViewController {
	
	private func setupBottomMenu() {
		torchButton = MenuButton("bolt.fill")
		recordButton = MenuButton(nil)
		lockButton = MenuButton("lock.fill")
		stackView = UIStackView(arrangedSubviews: [torchButton, recordButton, lockButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.distribution = .fillProportionally
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		view.insertSubview(redCircle, aboveSubview: recordButton)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 20),
			redCircle.heightAnchor.constraint(equalToConstant: 20),
			redCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
		])
	}
	
	private func setupSliders() {
		let y = UIApplication.shared.windows[0].safeAreaInsets.top + 5
		let popup = Popup(CGPoint(x: view.center.x, y: y))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 280), view.frame, .left)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.setRange(-3, 3, -0.5)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureTargetBias
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 280), view.frame, .right)
		focusSlider.setImage("globe")
		focusSlider.setRange(0, 1, 0.4)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		view.addSubview(focusSlider)
	}
	
	private func setupGrid() {
		let vert1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5,
			y: 0, width: 1, height: view.frame.height))
		let vert2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5,
			y: 0, width: 1, height: view.frame.height))
		let hor1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5,
			width: view.frame.width, height: 1))
		let hor2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5,
			width: view.frame.width, height: 1))
		
		for line in [vert1, vert2, hor1, hor2] {
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
	
	private func setupSecondary() {
		exposurePointView = MovablePoint()
		exposurePointView.center = view.center
		exposurePointView.camera = cam
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
	
	// MARK: - Buttons' handlers
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
			self.recordButton.backgroundColor = Colors.buttonDown
		})
	}
	
	@objc private func recordTouchUp() {
		if !cam.isRecording {
			cam.startRecording(self)
			recordButton.backgroundColor = Colors.buttonUp
			cam.durationAnim?.addCompletion({ _ in self.recordTouchUp() })
			cam.durationAnim?.startAnimation()
		} else {
			cam.stopRecording()
			if cam.output.recordedDuration.seconds > 0.25 {
				view.isUserInteractionEnabled = false
				UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
					self.blurView.alpha = 1
				})
			}
		}
		
		let args: (CGFloat, UIColor) = cam.isRecording ? (3.5, Colors.buttonUp) : (10, .black)
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = args.0
			if !self.cam.isRecording {
				self.recordButton.backgroundColor = args.1
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
	
	// MARK: - Sliders handlers & Secondary methods
	
	private func updateExposureTargetBias() {
		cam.setTargetBias(Float(exposureSlider.value))
	}
	
	private func updateLensPosition() {
		cam.setLensPosition(Float(focusSlider.value))
	}
	
	@objc private func didEnterBackground() {
		if let vc = presentedViewController as? PlayerController {
			vc.queuePlayer.pause()
		} else if cam.isRecording {
			recordTouchUp()
		}
		cam.stopSession()
	}
	
	@objc private func didBecomeActive() {
		cam.startSession()
		if let vc = presentedViewController as? PlayerController {
			vc.queuePlayer.play()
		} else if Settings.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	public func resetControls(_ duration: Double = 0) {
		view.isUserInteractionEnabled = true
		if Settings.shared.torchEnabled {
			cam.setTorch(.on)
		}
		touchesEnded(Set<UITouch>(), with: nil)
		UIView.animate(withDuration: duration * 0.8, delay: 0, options: .curveEaseOut, animations: {
			self.view.alpha = 1
			self.blurView.alpha = 0
		})
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
}


extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		guard output.recordedDuration.seconds > 0.25 else { return }
		playerController = PlayerController()
		playerController?.modalPresentationStyle = .overFullScreen
		if Settings.shared.torchEnabled {
			cam.setTorch(.off)
		}
		
		playerController?.setupPlayer(outputFileURL) { [weak self, weak playerController] (ready) in
			if ready {
				self?.present(playerController!, animated: true)
			} else {
				self?.resetControls()
				UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
					self?.blurView.alpha = 0
				})
				let error = Notification("Not enough memory", CGPoint(x: self!.view.center.x, y: self!.view.frame.height - 130))
				self?.view.addSubview(error)
				error.show()
			}
		}
	}
}
