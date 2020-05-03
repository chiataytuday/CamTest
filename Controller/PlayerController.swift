//
//  PlayerController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

final class PlayerController: UIViewController {

	var player: AVQueuePlayer!
	private var playerItem: AVPlayerItem!
	private var playerLayer: AVPlayerLayer!
	private var observer: NSKeyValueObservation?
	private var timer: Timer?
	
	private var exportPath: TemporaryFileURL?
	private var backButton, trimButton, muteButton: CustomButton!
	private var rangeSlider: RangeSlider!
	private var btnGroup: ButtonsGroup!
	private var statusBar: StatusBar!
	
	private let saveButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Save", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.setTitleColor(.systemGray, for: .normal)
		button.imageEdgeInsets.left = -14
		button.titleEdgeInsets.right = -2
		button.backgroundColor = .systemGray6
		button.tintColor = .systemGray
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
		let view = UIVisualEffectView(effect: effect)
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.alpha = 0
		return view
	}()
	
	
	override func viewDidLoad() {
		transitioningDelegate = self
		super.viewDidLoad()
		view.clipsToBounds = true
		view.backgroundColor = .systemBackground
	}
	
	deinit {
		print("OS deinits PlayerController: no leaks/allocations")
	}
	
	private func setupButtons() {
		backButton = CustomButton(.small, "xmark")
		trimButton = CustomButton(.small, "scissors")
		muteButton = CustomButton(.small, "speaker.slash.fill")
		btnGroup = ButtonsGroup([backButton, trimButton, muteButton])
		view.addSubview(btnGroup)
		NSLayoutConstraint.activate([
			btnGroup.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			btnGroup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30)
		])
		
		saveButton.layer.cornerRadius = 22.5
		view.addSubview(saveButton)
		NSLayoutConstraint.activate([
			saveButton.widthAnchor.constraint(equalToConstant: 110),
			saveButton.heightAnchor.constraint(equalToConstant: 45),
			saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
		])
		
		statusBar = StatusBar(contentsOf: ["scissors", "speaker.slash.fill"])
		view.addSubview(statusBar)
		let topMargin: CGFloat = User.shared.hasNotch ? 5 : 25
		NSLayoutConstraint.activate([
			statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topMargin),
			statusBar.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		rangeSlider = RangeSlider(frame: CGRect(x: view.center.x,
			y: view.frame.height - 5, width: view.frame.width - 60, height: 30))
		rangeSlider.alpha = 0
		view.addSubview(rangeSlider)
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	private func targetActions() {
		saveButton.addTarget(self, action: #selector(decreaseViewSize(sender:)), for: .touchDown)
		saveButton.addTarget(self, action: #selector(saveButtonUpInside(sender:)), for: .touchUpInside)
		saveButton.addTarget(self, action: #selector(resetViewSize(sender:)), for: .touchUpOutside)
		backButton.addTarget(self, action: #selector(decreaseViewSize(sender:)), for: .touchDown)
		backButton.addTarget(self, action: #selector(backButtonUpInside(sender:)), for: .touchUpInside)
		backButton.addTarget(self, action: #selector(resetViewSize(sender:)), for: .touchUpOutside)
		muteButton.addTarget(self, action: #selector(muteButtonDown(sender:)), for: .touchDown)
		trimButton.addTarget(self, action: #selector(trimButtonDown(sender:)), for: .touchDown)
	}
	
	func setupPlayer(_ url: URL, handler: @escaping (Bool) -> ()) {
		// Initialize player
		playerItem = AVPlayerItem(url: url)
		player = AVQueuePlayer(playerItem: playerItem)
		player.actionAtItemEnd = .pause
		playerLayer = AVPlayerLayer(player: player)
		playerLayer.frame = view.frame
		playerLayer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(playerLayer)
		
		// Buttons & slider
		setupButtons()
		targetActions()
		
		// Register events
		NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] (_) in
			self?.player.seek(to: self!.rangeSlider.startPoint.time, toleranceBefore: .zero, toleranceAfter: .zero)
			self?.player.play()
		}
		timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (t) in
			self?.observer?.invalidate()
			t.invalidate()
			handler(false)
		})
		observer = playerItem.observe(\.status, options: [.new], changeHandler: { [weak self] (item, _) in
			self?.timer?.invalidate()
			self?.timer = nil
			self?.observer?.invalidate()
			if item.status == .readyToPlay {
				self?.rangeSlider.videoPlayer = self?.player
				if UIApplication.shared.applicationState == .active {
					self?.player.play()
				}
			}
			handler(item.status == .readyToPlay)
		})
	}
	
	@objc private func muteButtonDown(sender: CustomButton) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		statusBar.setVisiblity(for: "speaker.slash.fill", player.isMuted)
		player.isMuted = !player.isMuted
		
		let args: (UIColor, UIColor) = player.isMuted ? (.systemGray5, .systemGray2) : (.systemGray6, .systemGray3)
		sender.backgroundColor = args.0
		sender.tintColor = args.1
	}
	
	@objc private func trimButtonDown(sender: UIButton) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		statusBar.setVisiblity(for: "scissors", rangeSlider.isShown)
		rangeSlider.isShown = !rangeSlider.isShown
		let args: (UIColor, UIColor, CGFloat, Double, UIView.AnimationCurve, CGFloat) =
			rangeSlider.isShown ? (.systemGray5, .systemGray2, -43, 0.1, .linear, 1) :
				(.systemGray6, .systemGray3, 0, 0.075, .easeIn, 0)
		
		trimButton.backgroundColor = args.0
		trimButton.tintColor = args.1
		trimButton.setTitleColor(args.1, for: .normal)
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.btnGroup.transform = CGAffineTransform(translationX: 0, y: args.2)
			self.saveButton.transform = CGAffineTransform(translationX: 0, y: args.2)
			self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: args.2)
		})
		UIViewPropertyAnimator(duration: args.3, curve: args.4) {
			self.rangeSlider.alpha = args.5
		}.startAnimation()
	}

	@objc private func saveButtonUpInside(sender: UIButton) {
		view.isUserInteractionEnabled = false
		saveVideoToLibrary()
		resetViewSize(sender: sender)
		closeController()
	}
	
	@objc private func backButtonUpInside(sender: UIButton) {
		view.isUserInteractionEnabled = false
		resetViewSize(sender: sender)
		closeController()
	}
	
	@objc private func decreaseViewSize(sender: UIButton?) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: .allowUserInteraction, animations: {
			self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.view.layer.cornerRadius = 18
			sender?.backgroundColor = .systemGray5
		})
	}
	
	@objc private func resetViewSize(sender: UIButton?) {
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
			self.view.transform = .identity
			self.view.layer.cornerRadius = 0
			sender?.backgroundColor = .systemGray6
		})
	}
	
	
	private func closeController() {
		UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
			self.blurEffectView.alpha = 1
		})
		player.pause()
		observer?.invalidate()
		dismiss(animated: true)
	}
	
	private func saveVideoToLibrary() {
		let timeRange = CMTimeRange(start: rangeSlider.startPoint.time, end: rangeSlider.endPoint.time)
		
		DispatchQueue.global(qos: .background).async {
			let rawAsset = self.playerItem.asset
			var assetToSave: AVAsset = rawAsset
			if self.player.isMuted {
				let videoTrack = rawAsset.tracks(withMediaType: .video).first
				let composition = AVMutableComposition()
				let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
				compVideoTrack!.preferredTransform = videoTrack!.preferredTransform
				let fullTimeRange = CMTimeRange(start: .zero, duration: rawAsset.duration)
				_ = try? compVideoTrack!.insertTimeRange(fullTimeRange, of: videoTrack!, at: .zero)
				assetToSave = composition
			}
			let exportSession = AVAssetExportSession(asset: assetToSave, presetName: AVAssetExportPreset1920x1080)
			self.exportPath = TemporaryFileURL(extension: "mp4")
			exportSession?.outputURL = self.exportPath?.contentURL
			exportSession?.outputFileType = .mp4
			exportSession?.timeRange = timeRange
			exportSession?.exportAsynchronously(completionHandler: {
				if exportSession?.status == .completed {
					UISaveVideoAtPathToSavedPhotosAlbum(self.exportPath!.contentURL.path, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
				}
			})
		}
	}
	
	@objc private func video(videoPath: String, didFinishSavingWithError error: NSError, contextInfo info: UnsafeMutableRawPointer) {
		exportPath = nil
		AppStoreReviewManager.requestReviewIfAppropriate()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if rangeSlider.isShown {
			rangeSlider.touchesBegan(touches, with: event)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if rangeSlider.isShown {
			rangeSlider.touchesMoved(touches, with: event)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		rangeSlider.touchesEnded(touches, with: event)
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.3, .present)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.28, .dismiss)
	}
}

extension UIView {
	func roundCorners(corners: UIRectCorner, radius: CGFloat) {
		let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		let mask = CAShapeLayer()
		mask.path = path.cgPath
		layer.mask = mask
	}
}
