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

final class CameraController: UIViewController {
	
	private var cam: Camera!
	private var photoBtn: PhotoButton!
	private var videoBtn: RecordButton!
	private var modeBtn: ModeButton!
	private var torchBtn, lockBtn, exposureBtn, lensBtn: CustomButton!
	private var toolsGroup, optionsGroup: ButtonsGroup!
	private var exposureSlider, lensSlider: VerticalSlider!
	private var exposurePoint: MovablePoint!
	private var statusBar: StatusBar!
	private var currentMode: Mode = .photo
	
	private var activeSlider: VerticalSlider?
	private var playerController: PlayerController?
	private var recordPath: TemporaryFileURL?
	
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
		
		videoBtn = RecordButton(.big, radius: 23)
		view.addSubview(videoBtn)
		NSLayoutConstraint.activate([
			videoBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			videoBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		videoBtn.isHidden = true
		
		torchBtn = CustomButton(.small, "bolt.fill")
		lockBtn = CustomButton(.small, "lock.fill")
		toolsGroup = ButtonsGroup([torchBtn, lockBtn])
		view.addSubview(toolsGroup)
		let widthQuarter = (view.frame.width/2 - 31.25)/2
		NSLayoutConstraint.activate([
			toolsGroup.centerYAnchor.constraint(equalTo: videoBtn.centerYAnchor),
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
		
		exposureBtn = CustomButton(.small, "sun.max.fill")
		lensBtn = CustomButton(.small, "scope")
		optionsGroup = ButtonsGroup([exposureBtn, lensBtn])
		view.addSubview(optionsGroup)
		NSLayoutConstraint.activate([
			optionsGroup.centerYAnchor.constraint(equalTo: videoBtn.centerYAnchor),
			optionsGroup.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -widthQuarter)
		])
		
		modeBtn = ModeButton()
		modeBtn.willSelect = { [weak self] in
			let activeBtn = self!.currentMode == .photo ? self!.photoBtn : self!.videoBtn
			activeBtn?.isUserInteractionEnabled = false
			UIView.animate(withDuration: 0.275, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
				activeBtn?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
				activeBtn?.backgroundColor = .systemGray5
			})
		}
		modeBtn.didChange = modeChanged(to:)
		modeBtn.clipsToBounds = false
		view.addSubview(modeBtn)
		NSLayoutConstraint.activate([
			modeBtn.centerXAnchor.constraint(equalTo: lensBtn.centerXAnchor)
		])
	}
	
	private func modeChanged(to mode: Mode) {
		var curBtn: CustomButton = currentMode == .photo ? photoBtn : videoBtn
		if mode != currentMode {
			currentMode = mode
				switch mode {
					case .video:
						modeBtn.icon.image = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
						photoBtn.isHidden = true
						videoBtn.isHidden = false
						curBtn = videoBtn
					case .photo:
						modeBtn.icon.image = UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
						videoBtn.isHidden = true
						photoBtn.isHidden = false
						curBtn = photoBtn
				}
			curBtn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		}
		
		curBtn.isUserInteractionEnabled = true
		curBtn.backgroundColor = .systemGray5
		UIView.animate(withDuration: 0.275, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			curBtn.transform = .identity
			curBtn.backgroundColor = .systemGray6
		})
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
			self?.cam.lockLens(at: Float(self!.lensSlider.value))
		}
		view.addSubview(lensSlider)
		lensSlider.align(to: .right)
	}
	
	private func setupAdditional() {
		statusBar = StatusBar(contentsOf: ["bolt.fill", "lock.fill", "sun.max.fill", "scope"])
		view.addSubview(statusBar)
		let topMargin: CGFloat = User.shared.hasNotch ? 5 : 25
		NSLayoutConstraint.activate([
			statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
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
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	private func targetActions() {
		for btn in [lockBtn, videoBtn, torchBtn, exposureBtn, lensBtn, photoBtn] {
			btn?.addTarget(btn, action: #selector(btn?.touchDown), for: .touchDown)
		}
		
		photoBtn.addTarget(photoBtn, action: #selector(photoBtn.touchUp), for: [.touchUpInside, .touchUpOutside])
		lockBtn.addTarget(self, action: #selector(changeExposureMode), for: .touchDown)
		torchBtn.addTarget(self, action: #selector(changeTorchMode), for: .touchDown)
		exposureBtn.addTarget(self, action: #selector(onOffManualExposure), for: .touchDown)
		lensBtn.addTarget(self, action: #selector(onOffManualLens), for: .touchDown)
		videoBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		videoBtn.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
	}
	
	// MARK: - Buttons' handlers
	
	@objc private func recordTouchUp() {
		videoBtn.touchUp(camIsRecording: cam.isRecording)
		
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
		cam.setExposure(mode) { [weak self] in
			User.shared.exposureMode = mode
			self?.statusBar.setVisiblity(for: "lock.fill", isLocked)
		}
	}
	
	@objc private func changeTorchMode() {
		let torchEnabled = cam.captureDevice.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		cam.torch(mode) { [weak self] in
			User.shared.torchEnabled = !torchEnabled
			self?.statusBar.setVisiblity(for: "bolt.fill", torchEnabled)
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
			cam.lockLens(at: Float(lensSlider.value))
		} else {
			cam.resetLens()
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
			cam.torch(.on)
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
			cam.torch(.on)
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
			cam.torch(.off)
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
		DispatchQueue.main.async {
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
