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
	var photoBtn: PhotoButton!
	var recordBtn: RecordButton!
	var modeBtn: ModeButton!
	var torchBtn, lockBtn, exposureBtn, lensBtn: CustomButton!
	var toolsGroup, optionsGroup: ButtonsGroup!
	var exposureSlider, lensSlider: VerticalSlider!
	var exposurePoint, lensPoint: MovablePoint!
	var statusBar: StatusBar!
	var currentMode: Mode = .video
	
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
	
	var blackView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		view.alpha = 0
		return view
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		
		setupButtons()
		targetActions()
		setupSliders()
		cam = Camera()
		photoBtn.cam = cam
		cam.attachPreview(to: view)
		setupAdditional()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: view).x
		if let slider = touchX > view.frame.width/2 ? lensSlider : exposureSlider, slider.isActive {
			activeSlider = slider
			if activeSlider == lensSlider {
				lensSlider.set(value: CGFloat(cam.captureDevice.lensPosition))
			}
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
		blackView.frame = view.frame
		view.addSubview(blackView)
		
		recordBtn = RecordButton(.big, radius: 23)
		view.addSubview(recordBtn)
		NSLayoutConstraint.activate([
			recordBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
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
		
		let trackerPos = CGPoint(x: view.center.x, y: view.frame.height - 120)
		let tracker = Tracker(center: trackerPos, maxNumber: 20)
		view.addSubview(tracker)
		
		photoBtn = PhotoButton(.big, radius: 23, view: blackView, tracker: tracker, delegate: self)
		view.addSubview(photoBtn)
		NSLayoutConstraint.activate([
			photoBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			photoBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		photoBtn.isHidden = true
		
		exposureBtn = CustomButton(.small, "sun.max.fill")
		lensBtn = CustomButton(.small, "scope")
		optionsGroup = ButtonsGroup([exposureBtn, lensBtn])
		view.addSubview(optionsGroup)
		NSLayoutConstraint.activate([
			optionsGroup.centerYAnchor.constraint(equalTo: recordBtn.centerYAnchor),
			optionsGroup.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -widthQuarter)
		])
		
		modeBtn = ModeButton()
		modeBtn.delegate = modeWasChanged(to:)
		modeBtn.clipsToBounds = false
		view.addSubview(modeBtn)
		NSLayoutConstraint.activate([
			modeBtn.centerXAnchor.constraint(equalTo: lensBtn.centerXAnchor, constant: 15)
		])
	}
	
	private func modeWasChanged(to mode: Mode) {
		if (mode != currentMode) {
			currentMode = mode
			switch mode {
				case .video:
					modeBtn.circleView.image = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
					photoBtn.isHidden = true
					recordBtn.isHidden = false
					recordBtn.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
					UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [], animations: {
						self.recordBtn.transform = .identity
					})
				case .photo:
					modeBtn.circleView.image = UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .regular))
					photoBtn.isHidden = false
					recordBtn.isHidden = true
					photoBtn.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
					UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [], animations: {
						self.photoBtn.transform = .identity
					})
			}
		}
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
		statusBar = StatusBar(contentsOf: ["bolt.fill", "lock.fill", "sun.max.fill", "scope"])
		view.addSubview(statusBar)
		NSLayoutConstraint.activate([
			statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25),
			statusBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			modeBtn.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
		])
		
		exposurePoint = MovablePoint(symbolName: "sun.max.fill")
		exposurePoint.center = view.center
		exposurePoint.moved = { [weak self] in
			self?.cam.setExposure(.autoExpose, self!.exposurePoint.center)
		}
		exposurePoint.ended = { [weak self] in
			self?.cam.setExposure(User.shared.exposureMode, self!.exposurePoint.center)
		}
		exposurePoint.cam = cam
		view.addSubview(exposurePoint)
		
		lensPoint = MovablePoint(symbolName: "scope")
		lensPoint.center = view.center
		lensPoint.ended = { [weak self] in
			self?.cam.setLensAuto(.autoFocus, self!.lensPoint.center)
		}
		lensPoint.alpha = 0
		lensPoint.cam = cam
		view.addSubview(lensPoint)
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	private func targetActions() {
		for btn in [lockBtn, recordBtn, torchBtn, exposureBtn, lensBtn, photoBtn] {
			btn?.addTarget(btn, action: #selector(btn?.touchDown), for: .touchDown)
		}
		
		photoBtn.addTarget(photoBtn, action: #selector(photoBtn.touchUp), for: [.touchUpInside, .touchUpOutside])
		lockBtn.addTarget(self, action: #selector(changeExposureMode), for: .touchDown)
		torchBtn.addTarget(self, action: #selector(changeTorchMode), for: .touchDown)
		exposureBtn.addTarget(self, action: #selector(onOffManualExposure), for: .touchDown)
		lensBtn.addTarget(self, action: #selector(onOffManualLens), for: .touchDown)
		recordBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
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
		cam.setExposure(mode) {
			User.shared.exposureMode = mode
			self.statusBar.setVisiblity(for: "lock.fill", isLocked)
		}
	}
	
	@objc private func changeTorchMode() {
		let torchEnabled = cam.captureDevice.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		cam.setTorch(mode) {
			User.shared.torchEnabled = !torchEnabled
			self.statusBar.setVisiblity(for: "bolt.fill", torchEnabled)
		}
	}
	
	@objc private func onOffManualExposure() {
		statusBar.setVisiblity(for: "sun.max.fill", exposureSlider.isActive)
		if exposureBtn.isActive {
			cam.setTargetBias(Float(exposureSlider.value))
		} else {
			cam.setTargetBias(0)
		}
		exposureSlider.isActive = exposureBtn.isActive
	}
	
	@objc private func onOffManualLens() {
		statusBar.setVisiblity(for: "scope", lensSlider.isActive)
		let lensPosition = cam.captureDevice.lensPosition
		lensSlider.set(value: CGFloat(lensPosition))
		
		let isLocked = cam.captureDevice.focusMode != .continuousAutoFocus
		let mode: AVCaptureDevice.FocusMode = isLocked ? .continuousAutoFocus : .locked
		User.shared.focusMode = mode
		if lensBtn.isActive {
			cam.setLensLocked(at: Float(lensSlider.value))
			lensPoint.show()
		} else {
			cam.setLensAuto(mode, lensPoint.center)
			lensPoint.hide()
		}
		lensSlider.isActive = lensBtn.isActive
	}
	
	// MARK: - Secondary methods
	
	@objc private func didEnterBackground() {
		cam.captureSession.stopRunning()
	}
	
	@objc private func didBecomeActive() {
		cam.previewView.videoPreviewLayer.connection?.isEnabled = true
		cam.captureSession.startRunning()
		if let vc = presentedViewController as? PlayerController {
			vc.player.play()
		} else if User.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	@objc private func willResignActive() {
		cam.previewView.videoPreviewLayer.connection?.isEnabled = false
		if let vc = presentedViewController as? PlayerController {
			vc.player.pause()
		} else if cam.isRecording {
			recordTouchUp()
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
				let error = Notification(text: "Something went wrong")
				error.center = CGPoint(x: self!.view.center.x, y: self!.view.frame.height - 130)
				self?.view.addSubview(error)
				error.show(for: 1)
			}
		}
	}
}

extension CameraController: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
		DispatchQueue.global(qos: .background).async {
			UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
		}
	}
}

extension UIView {
	func show() {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [], animations: {
			self.transform = .identity
		})
		UIViewPropertyAnimator(duration: 0.075, curve: .easeOut) {
			self.alpha = 1
		}.startAnimation()
	}
	
	func hide() {
		UIView.animate(withDuration: 0.12, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
		})
		UIViewPropertyAnimator(duration: 0.06, curve: .easeIn) {
			self.alpha = 0
		}.startAnimation()
	}
}
