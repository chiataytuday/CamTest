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

protocol Notifiable {
	func videoSaved()
}

final class CameraController: UIViewController, Notifiable {

	func videoSaved() {
		let notification = Notification(text: "Saved it!")
		notification.center = CGPoint(x: view.center.x, y: view.frame.height - 130)
		notification.backgroundColor = UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)
		view.addSubview(notification)
		notification.show(for: 1)
	}
	
	private var camera: Camera!
	private var photoButton: PhotoButton!
	private var videoButton: RecordButton!
	private var modeButton: ModeButton!
	private var flashButton, lockButton, exposureButton, lensButton: CustomButton!
	private var toolsGroup, optionsGroup: ButtonsGroup!
	private var exposureSlider, lensSlider: VerticalSlider!
	private var exposurePoint: MovablePoint!
	private var statusBar: StatusBar!
	private var currentMode: Mode = .photo
	
	private var activeSlider: VerticalSlider?
	private var playerController: PlayerController?
	private var recordPath: TemporaryFileURL?

	var topMargin, bottomMargin: CGFloat!
	var grid: UIView!

	var gridButton: UIView!
	
	let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: .regular)
		let effectView = UIVisualEffectView(effect: effect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	var blinkView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		view.alpha = 0
		return view
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground

		setupGrid()
		setupBottomButtons()
		setupTopButtons()
		targetActions()
		setupSliders()
		camera = Camera()
		photoButton.cam = camera
		camera.attachPreview(to: view)
		setupMovablePoints()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: view).x
		if let slider = touchX > view.frame.width/2 ? lensSlider : exposureSlider, slider.isActive {
			activeSlider = slider
			if activeSlider == lensSlider {
				lensSlider.set(value: CGFloat(camera.captureDevice.lensPosition))
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

	private func setupBottomButtons() {

		/* Define top and bottom margins for UI */

		topMargin = 5
		bottomMargin = 0

		/* Setup video button */

		videoButton = RecordButton(.big, radius: 23)
		videoButton.isHidden = true
		view.addSubview(videoButton)
		NSLayoutConstraint.activate([
			videoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomMargin),
			videoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])

		/* Setup photo button */

		blinkView.frame = view.frame
		view.addSubview(blinkView)

		let counterPosition = CGPoint(x: view.center.x, y: view.frame.height - 120)
		let photoCounter = Tracker(center: counterPosition, maxNumber: 20)
		view.addSubview(photoCounter)

		photoButton = PhotoButton(.big, radius: 23, view: blinkView, tracker: photoCounter, delegate: self)
		view.addSubview(photoButton)
		NSLayoutConstraint.activate([
			photoButton.bottomAnchor.constraint(equalTo: videoButton.bottomAnchor),
			photoButton.centerXAnchor.constraint(equalTo: videoButton.centerXAnchor)
		])

		/* Setup left stackview */

		flashButton = CustomButton(.small, "bolt.fill")
		lockButton = CustomButton(.small, "lock.fill")
		toolsGroup = ButtonsGroup([flashButton, lockButton])
		view.addSubview(toolsGroup)
		let widthQuarter = (view.frame.width/2 - 58)/2
		NSLayoutConstraint.activate([
			toolsGroup.centerYAnchor.constraint(equalTo: videoButton.centerYAnchor),
			toolsGroup.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: widthQuarter)
		])

		/* Setup right stackview */

		exposureButton = CustomButton(.small, "sun.max.fill")
		lensButton = CustomButton(.small, "scope")
		optionsGroup = ButtonsGroup([exposureButton, lensButton])
		view.addSubview(optionsGroup)
		NSLayoutConstraint.activate([
			optionsGroup.centerYAnchor.constraint(equalTo: videoButton.centerYAnchor),
			optionsGroup.centerXAnchor.constraint(equalTo: view.trailingAnchor, constant: -widthQuarter)
		])
	}

	private func setupTopButtons() {

		/* Status bar setup */

		statusBar = StatusBar(contentsOf: ["bolt.fill", "lock.fill", "sun.max.fill", "scope"])
		view.addSubview(statusBar)
		NSLayoutConstraint.activate([
			statusBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin)
		])

		/* Mode button setup */

		modeButton = ModeButton()
		modeButton.willSelect = modeSelectionWillChange
		modeButton.didChange = modeDidChange(to:)
		modeButton.clipsToBounds = false
		view.addSubview(modeButton)
		NSLayoutConstraint.activate([
			modeButton.centerXAnchor.constraint(equalTo: lensButton.centerXAnchor),
			modeButton.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
		])

		gridButton = GridButton(grid)
		view.addSubview(gridButton)
		NSLayoutConstraint.activate([
			gridButton.centerXAnchor.constraint(equalTo: flashButton.centerXAnchor),
			gridButton.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
		])
	}

	private func modeSelectionWillChange() {
		let currentButton = currentMode == .photo ? photoButton : videoButton
		currentButton?.isUserInteractionEnabled = false
		UIView.animate(withDuration: 0.275, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			currentButton?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			currentButton?.backgroundColor = .systemGray5
		})
	}

	private func modeDidChange(to mode: Mode) {

		/* Change mode button icon,
		Make selected capture button visible
		*/

		var currentButton = currentMode == .photo ? photoButton : videoButton
		if mode != currentMode {
			currentMode = mode

			if currentMode == .video {
				modeButton.icon.image = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
				photoButton.isHidden = true
				videoButton.isHidden = false
				currentButton = videoButton
			} else {
				modeButton.icon.image = UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
				videoButton.isHidden = true
				photoButton.isHidden = false
				currentButton = photoButton
			}
			currentButton?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		}

		/* Animate selected capture button */

		currentButton?.isUserInteractionEnabled = true
		currentButton?.backgroundColor = .systemGray5
		UIView.animate(withDuration: 0.275, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			currentButton?.transform = .identity
			currentButton?.backgroundColor = .systemGray6
		})
	}

	private func setupGrid() {

		/* Configure lines layer */

		let offsets = CGPoint(x: view.frame.width/6, y: view.frame.height/6)
		grid = UIView(frame: view.frame)
		grid.isUserInteractionEnabled = false
		grid.layer.shadowColor = UIColor.black.cgColor
		grid.layer.shadowRadius = 1.5
		grid.layer.shadowOffset.height = -0.75
		grid.layer.shadowOpacity = 0.4
		grid.alpha = 0

		/* Layout lines */

		let leftLine = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 1, height: view.frame.height)))
		leftLine.center = CGPoint(x: offsets.x * 2, y: view.center.y)
		leftLine.backgroundColor = .white
		grid.addSubview(leftLine)

		let rightLine = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 1, height: view.frame.height)))
		rightLine.center = CGPoint(x: offsets.x * 4, y: view.center.y)
		rightLine.backgroundColor = .white
		grid.addSubview(rightLine)

		let bottomLine = UIView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 1)))
		bottomLine.center = CGPoint(x: view.center.x, y: offsets.y * 2)
		bottomLine.backgroundColor = .white
		grid.addSubview(bottomLine)

		let topLine = UIView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 1)))
		topLine.center = CGPoint(x: view.center.x, y: offsets.y * 4)
		topLine.backgroundColor = .white
		grid.addSubview(topLine)

		/* Add to the view */

		grid.center = view.center
		view.addSubview(grid)
	}
	
	private func setupSliders() {

		/* Exposure slider */

		exposureSlider = VerticalSlider(CGSize(width: 40, height: 300))
		exposureSlider.range(min: -3, max: 3, value: 0)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.delegate = { [weak self] in
			self?.camera.setTargetBias(Float(self!.exposureSlider.value))
		}
		view.addSubview(exposureSlider)
		exposureSlider.align(to: .left)

		/* Lens slider */
		
		lensSlider = VerticalSlider(CGSize(width: 40, height: 300))
		lensSlider.range(min: 0, max: 1, value: 0.4)
		lensSlider.setImage("scope")
		lensSlider.delegate = { [weak self] in
			self?.camera.lockLens(at: Float(self!.lensSlider.value))
		}
		view.addSubview(lensSlider)
		lensSlider.align(to: .right)
	}

	private func setupMovablePoints() {
		exposurePoint = MovablePoint(symbolName: "sun.max.fill")
		exposurePoint.center = view.center
		exposurePoint.moved = { [weak self] in
			self?.camera.setExposure(.autoExpose, self!.exposurePoint.center)
		}
		exposurePoint.ended = { [weak self] in
			self?.camera.setExposure(User.shared.exposureMode, self!.exposurePoint.center)
		}
		exposurePoint.cam = camera
		view.addSubview(exposurePoint)

		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	private func targetActions() {
		for btn in [lockButton, videoButton, flashButton, exposureButton, lensButton, photoButton] {
			btn?.addTarget(btn, action: #selector(btn?.touchDown), for: .touchDown)
		}

		photoButton.addTarget(photoButton, action: #selector(photoButton.touchUp), for: [.touchUpInside, .touchUpOutside])
		lockButton.addTarget(self, action: #selector(changeExposureMode), for: .touchDown)
		flashButton.addTarget(self, action: #selector(changeTorchMode), for: .touchDown)
		exposureButton.addTarget(self, action: #selector(onOffManualExposure), for: .touchDown)
		lensButton.addTarget(self, action: #selector(onOffManualLens), for: .touchDown)
		videoButton.addTarget(self, action: #selector(captureTouchUp), for: .touchUpInside)
		videoButton.addTarget(self, action: #selector(captureTouchUp), for: .touchUpOutside)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
	}

}

extension CameraController {
	
	@objc private func captureTouchUp() {
		videoButton.touchUp(camIsRecording: camera.isRecording)
		
		if !camera.isRecording {
			recordPath = TemporaryFileURL(extension: "mp4")
			camera.startRecording(to: recordPath!.contentURL, self)
			camera.durationAnim?.addCompletion({ [weak self] _ in
				self?.captureTouchUp()
			})
			camera.durationAnim?.startAnimation()
			optionsGroup.hide(); toolsGroup.hide(); statusBar.hide(); modeButton.hide(); gridButton.hide()
		} else {
			view.isUserInteractionEnabled = false
			camera.stopRecording()
		}
	}
	
	@objc private func changeExposureMode() {
		let isLocked = camera.captureDevice.exposureMode == .locked
		let mode: AVCaptureDevice.ExposureMode = isLocked ? .continuousAutoExposure : .locked
		camera.setExposure(mode) { [weak self] in
			User.shared.exposureMode = mode
			self?.statusBar.setVisiblity(for: "lock.fill", isLocked)
		}
	}
	
	@objc private func changeTorchMode() {
		let torchEnabled = camera.captureDevice.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		camera.torch(mode) { [weak self] in
			User.shared.torchEnabled = !torchEnabled
			self?.statusBar.setVisiblity(for: "bolt.fill", torchEnabled)
		}
	}
	
	@objc private func onOffManualExposure() {
		statusBar.setVisiblity(for: "sun.max.fill", exposureSlider.isActive)
		if exposureButton.isActive {
			camera.setTargetBias(Float(exposureSlider.value))
		} else {
			camera.setTargetBias(0)
		}
		exposureSlider.isActive = exposureButton.isActive
	}
	
	@objc private func onOffManualLens() {
		statusBar.setVisiblity(for: "scope", lensSlider.isActive)
		let lensPosition = camera.captureDevice.lensPosition
		lensSlider.set(value: CGFloat(lensPosition))
		
		let isLocked = camera.captureDevice.focusMode != .continuousAutoFocus
		let mode: AVCaptureDevice.FocusMode = isLocked ? .continuousAutoFocus : .locked
		User.shared.focusMode = mode
		if lensButton.isActive {
			camera.lockLens(at: Float(lensSlider.value))
		} else {
			camera.resetLens()
		}
		lensSlider.isActive = lensButton.isActive
	}
	
	// MARK: - Secondary methods
	
	@objc private func didEnterBackground() {
		camera.captureSession.stopRunning()
	}
	
	@objc private func didBecomeActive() {
		camera.previewView.videoPreviewLayer.connection?.isEnabled = true
		camera.captureSession.startRunning()
		if let vc = presentedViewController as? PlayerController {
			vc.player.play()
		} else if User.shared.torchEnabled {
			camera.torch(.on)
		}
	}
	
	@objc private func willResignActive() {
		camera.previewView.videoPreviewLayer.connection?.isEnabled = false
		if let vc = presentedViewController as? PlayerController {
			vc.player.pause()
		} else if camera.isRecording {
			captureTouchUp()
		}
	}
	
	func resetView() {
		camera.previewView.videoPreviewLayer.connection?.isEnabled = true
		view.isUserInteractionEnabled = true
		if User.shared.torchEnabled {
			camera.torch(.on)
		}
		touchesEnded(Set<UITouch>(), with: nil)
		optionsGroup.show(); toolsGroup.show(); modeButton.show(); gridButton.show()
		statusBar.transform = .identity
		statusBar.alpha = 1
		playerController = nil
	}
}


extension CameraController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		if User.shared.torchEnabled {
			camera.torch(.off)
		}
		playerController = PlayerController()
		playerController?.delegate = self
		playerController?.additionalSafeAreaInsets = additionalSafeAreaInsets
		playerController?.modalPresentationStyle = .overFullScreen
		playerController?.setupPlayer(outputFileURL) { [weak self, weak playerController] (ready) in
			self?.camera.previewView.videoPreviewLayer.connection?.isEnabled = false
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
