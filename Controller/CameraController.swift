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
	
	var cam: Camera!
	var exposureSlider, lensSlider: VerticalSlider!
	var torchBtn, lockBtn, exposureBtn, lensBtn: CustomButton!
	var recordBtn: RecordButton!
	var toolsGroup, optionsGroup: ButtonsGroup!
	var exposurePointView: MovablePoint!
	var statusBar: StatusBar!
	
	var activeSlider: VerticalSlider?
	var playerController: PlayerController?
	var recordPath: TemporaryFileURL?
	
	let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: .regular)
		let effectView = UIVisualEffectView(effect: effect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		
		setupButtons()
		targetActions()
		setupSliders()
		cam = Camera()
		cam.attachPreview(to: view)
		setupAdditional()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: view).x
		if let s = touchX > view.frame.width/2 ? lensSlider : exposureSlider, s.isActive {
			activeSlider = s
		}
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
	
	private func setupButtons() {
		recordBtn = RecordButton(.big, radius: 23)
		view.addSubview(recordBtn)
		NSLayoutConstraint.activate([
			recordBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
			recordBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		torchBtn = CustomButton(.small, "bolt.fill")
		lockBtn = CustomButton(.small, "lock.fill")
		toolsGroup = ButtonsGroup([torchBtn, lockBtn])
		view.addSubview(toolsGroup)
		let widthQuarter = (view.frame.width/2 - 31.25)/2
		NSLayoutConstraint.activate([
			toolsGroup.centerYAnchor.constraint(equalTo: recordBtn.centerYAnchor),
			toolsGroup.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: widthQuarter)
		])
		
		exposureBtn = CustomButton(.small, "sun.max.fill")
		lensBtn = CustomButton(.small, "scope")
		optionsGroup = ButtonsGroup([exposureBtn, lensBtn])
		view.addSubview(optionsGroup)
		NSLayoutConstraint.activate([
			optionsGroup.centerYAnchor.constraint(equalTo: recordBtn.centerYAnchor),
			optionsGroup.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -widthQuarter)
		])
	}
	
	private func setupSliders() {
		exposureSlider = VerticalSlider(CGSize(width: 40, height: 280))
		exposureSlider.range(min: -3, max: 3, value: 0)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.delegate = { [weak self] in
			self?.cam.setTargetBias(Float(self!.exposureSlider.value))
		}
		view.addSubview(exposureSlider)
		exposureSlider.align(to: .left)
		
		lensSlider = VerticalSlider(CGSize(width: 40, height: 280))
		lensSlider.range(min: 0, max: 1, value: 0.4)
		lensSlider.setImage("scope")
		lensSlider.delegate = { [weak self] in
			self?.cam.setLensLocked(at: Float(self!.lensSlider.value))
		}
		view.addSubview(lensSlider)
		lensSlider.align(to: .right)
	}
	
	private func setupAdditional() {
		statusBar = StatusBar()
		view.addSubview(statusBar)
		NSLayoutConstraint.activate([
			statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
			statusBar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		exposurePointView = MovablePoint()
		exposurePointView.center = view.center
		exposurePointView.cam = cam
		view.addSubview(exposurePointView)
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	private func targetActions() {
		for btn in [lockBtn, recordBtn, torchBtn, exposureBtn, lensBtn] {
			btn?.addTarget(btn, action: #selector(btn?.touchDown), for: .touchDown)
		}
		
		lockBtn.addTarget(self, action: #selector(changeExposureMode), for: .touchDown)
		torchBtn.addTarget(self, action: #selector(changeTorchMode), for: .touchDown)
		exposureBtn.addTarget(self, action: #selector(onOffManualExposure), for: .touchDown)
		lensBtn.addTarget(self, action: #selector(onOffManualLens), for: .touchDown)
		recordBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
	}
	
	// MARK: - Buttons' handlers
	
	@objc private func recordTouchUp() {
		recordBtn.touchUp(camIsRecording: cam.isRecording)
		
		if !cam.isRecording {
			recordPath = TemporaryFileURL(extension: "mp4")
			cam.startRecording(to: recordPath!.contentURL, self)
			cam.durationAnim?.addCompletion({ [weak self] _ in
				self?.recordTouchUp()
			})
			cam.durationAnim?.startAnimation()
			optionsGroup.hide(); toolsGroup.hide(); statusBar.hide()
		} else {
			view.isUserInteractionEnabled = false
			cam.stopRecording()
		}
	}
	
	@objc private func changeExposureMode() {
		let isLocked = cam.captureDevice.exposureMode == .locked
		let mode: AVCaptureDevice.ExposureMode = isLocked ? .continuousAutoExposure : .locked
		User.shared.exposureMode = mode
		statusBar.animate(statusBar.lockItem, isLocked)
		cam.setExposure(mode)
	}
	
	@objc private func changeTorchMode() {
		let torchEnabled = cam.captureDevice.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		User.shared.torchEnabled = !torchEnabled
		statusBar.animate(statusBar.torchItem, torchEnabled)
		cam.setTorch(mode)
	}
	
	@objc private func onOffManualExposure() {
		statusBar.animate(statusBar.exposureItem, exposureSlider.isActive)
		if exposureBtn.isActive {
			cam.setTargetBias(Float(exposureSlider.value))
			exposureSlider.isActive = true
		} else {
			cam.setTargetBias(0)
			exposureSlider.isActive = false
		}
	}
	
	@objc private func onOffManualLens() {
		statusBar.animate(statusBar.lensItem, lensSlider.isActive)
		let lensPosition = cam.captureDevice.lensPosition
		lensSlider.set(value: CGFloat(lensPosition))
		if lensBtn.isActive {
			cam.setLensLocked(at: Float(lensSlider.value))
			lensSlider.isActive = true
		} else {
			cam.setLensAuto()
			lensSlider.isActive = false
		}
	}
	
	// MARK: - Secondary methods
	
	@objc private func didEnterBackground() {
		if let vc = presentedViewController as? PlayerController {
			vc.player.pause()
		} else if cam.isRecording {
			recordTouchUp()
		}
		cam.captureSession.stopRunning()
	}
	
	@objc private func didBecomeActive() {
		cam.captureSession.startRunning()
		if let vc = presentedViewController as? PlayerController {
			vc.player.play()
		} else if User.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	func resetView() {
		cam.previewView.videoPreviewLayer.connection?.isEnabled = true
		view.isUserInteractionEnabled = true
		if User.shared.torchEnabled {
			cam.setTorch(.on)
		}
		touchesEnded(Set<UITouch>(), with: nil)
		optionsGroup.show(); toolsGroup.show()
		statusBar.transform = .identity
		statusBar.alpha = 1
		playerController = nil
	}
}


extension CameraController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		if User.shared.torchEnabled {
			cam.setTorch(.off)
		}
		playerController = PlayerController()
		playerController?.modalPresentationStyle = .overFullScreen
		playerController?.setupPlayer(outputFileURL) { [weak self, weak playerController] (ready) in
			self?.cam.previewView.videoPreviewLayer.connection?.isEnabled = false
			self?.recordPath = nil
			if ready {
				self?.present(playerController!, animated: true)
			} else {
				self?.resetView()
				let error = Notification(text: "Something went wrong", color: .systemRed)
				error.center = CGPoint(x: self!.view.center.x, y: self!.view.frame.height - 130)
				self?.view.addSubview(error)
				error.present(for: 1)
			}
		}
	}
}
