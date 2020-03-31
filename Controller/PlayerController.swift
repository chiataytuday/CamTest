//
//  PlayerController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class PlayerController: UIViewController {
	
	private var recordURL: URL!
	private var outputURL: URL?
	private var btnStackView: UIStackView!
	private var playerLayer: AVPlayerLayer!
	private var playerItem: AVPlayerItem!
	var queuePlayer: AVQueuePlayer!
	var rangeSlider: RangeSlider!
	var timer: Timer?
	
	private let saveButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Save", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.setTitleColor(Colors.gray5, for: .normal)
		button.imageEdgeInsets.left = -8
		button.titleEdgeInsets.right = -8
		button.backgroundColor = .black
		button.tintColor = Colors.gray5
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let backButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.tintColor = Colors.gray3
		button.backgroundColor = .black
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let trimButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "scissors"), for: .normal)
		button.tintColor = Colors.gray3
		button.backgroundColor = .black
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
		let view = UIVisualEffectView(effect: effect)
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.alpha = 1
		return view
	}()
	
	
	override func viewDidLoad() {
		transitioningDelegate = self
		super.viewDidLoad()
		view.clipsToBounds = true
		view.backgroundColor = .black
	}
	
	override func viewDidLayoutSubviews() {
		saveButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 16.5)
		backButton.roundCorners(corners: [.topRight, .bottomRight], radius: 16.5)
	}
	
	deinit {
		print("OS deinits PlayerController: NO memory leaks/retain cycles")
	}
	
	
	private func setupSubviews() {
		saveButton.addTarget(self, action: #selector(decreaseViewSize(sender:)), for: .touchDown)
		saveButton.addTarget(self, action: #selector(saveButtonUpInside(sender:)), for: .touchUpInside)
		saveButton.addTarget(self, action: #selector(resetViewSize(sender:)), for: .touchUpOutside)
		NSLayoutConstraint.activate([
			saveButton.widthAnchor.constraint(equalToConstant: 100),
			saveButton.heightAnchor.constraint(equalToConstant: 48),
		])
		
		backButton.addTarget(self, action: #selector(decreaseViewSize(sender:)), for: .touchDown)
		backButton.addTarget(self, action: #selector(backButtonUpInside(sender:)), for: .touchUpInside)
		backButton.addTarget(self, action: #selector(resetViewSize(sender:)), for: .touchUpOutside)
		NSLayoutConstraint.activate([
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 48)
		])
		
		trimButton.addTarget(self, action: #selector(trimButtonDown(sender:)), for: .touchDown)
		NSLayoutConstraint.activate([
			trimButton.widthAnchor.constraint(equalToConstant: 50),
			trimButton.heightAnchor.constraint(equalToConstant: 48)
		])
		
		btnStackView = UIStackView(arrangedSubviews: [saveButton, trimButton, backButton])
		btnStackView.translatesAutoresizingMaskIntoConstraints = false
		btnStackView.alignment = .center
		btnStackView.distribution = .fillProportionally
		btnStackView.spacing = -1
		view.addSubview(btnStackView)
		NSLayoutConstraint.activate([
			btnStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			btnStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
		])
		
		rangeSlider = RangeSlider(frame: CGRect(x: view.center.x,
			y: view.frame.height - 5, width: view.frame.width - 60, height: 30))
		rangeSlider.alpha = 0
		view.addSubview(rangeSlider)
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	public func setupPlayer(_ url: URL, handler: @escaping (Bool) -> ()) {
		self.recordURL = url
		playerItem = AVPlayerItem(url: url)
		queuePlayer = AVQueuePlayer(playerItem: playerItem)
		queuePlayer.actionAtItemEnd = .pause
		NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] (_) in
			self?.queuePlayer.seek(to: self!.rangeSlider.begin.time!, toleranceBefore: .zero, toleranceAfter: .zero)
			self?.queuePlayer.play()
		}
		
		playerLayer = AVPlayerLayer(player: queuePlayer)
		playerLayer.frame = view.frame
		playerLayer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(playerLayer)
		setupSubviews()
		timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (t) in
			self?.observer?.invalidate()
			t.invalidate()
			handler(false)
		})
		observer = playerItem.observe(\.status, options: [.new], changeHandler: { [weak self] (item, change) in
			if item.status == .readyToPlay {
				self?.rangeSlider.videoPlayer = self?.queuePlayer
				self?.queuePlayer.play()
			}
			self?.timer?.invalidate()
			self?.observer?.invalidate()
			handler(item.status == .readyToPlay)
		})
	}
	
	var observer: NSKeyValueObservation?
	
	
	@objc private func trimButtonDown(sender: UIButton) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		rangeSlider.isPresented = !rangeSlider.isPresented
		let args: (UIColor, CGFloat, Double, UIView.AnimationCurve, CGFloat) = rangeSlider.isPresented ? (Colors.gray1, -45, 0.1, .linear, 1) : (.black, 0, 0.075, .easeIn, 0)
		
		trimButton.backgroundColor = args.0
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.btnStackView.transform = CGAffineTransform(translationX: 0, y: args.1)
			self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: args.1)
		})
		UIViewPropertyAnimator(duration: args.2, curve: args.3) {
			self.rangeSlider.alpha = args.4
		}.startAnimation()
	}

	@objc private func saveButtonUpInside(sender: UIButton) {
		saveVideoToLibrary()
		resetViewSize(sender: sender)
		closeController()
	}
	
	@objc private func backButtonUpInside(sender: UIButton) {
		cleanUpDocumentDirectory()
		resetViewSize(sender: sender)
		closeController()
	}
	
	@objc private func decreaseViewSize(sender: UIButton?) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.view.layer.cornerRadius = 20
			sender?.backgroundColor = Colors.gray1
		})
	}
	
	@objc private func resetViewSize(sender: UIButton?) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.view.transform = CGAffineTransform.identity
			self.view.layer.cornerRadius = 0
			sender?.backgroundColor = .black
		})
	}
	
	
	private func closeController() {
		UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
			self.blurEffectView.alpha = 1
		})
		queuePlayer.pause()
		observer?.invalidate()
		dismiss(animated: true)
	}
	
	private func saveVideoToLibrary() {
		let asset = AVAsset(url: recordURL)
		let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
		outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("output").appendingPathExtension("mp4")
		exportSession?.outputURL = outputURL
		exportSession?.outputFileType = .mp4
		let range = CMTimeRange(start: rangeSlider.begin.time!, end: rangeSlider.end.time!)
		exportSession?.timeRange = range
		
		exportSession?.exportAsynchronously(completionHandler: {
			if exportSession?.status == .completed {
				UISaveVideoAtPathToSavedPhotosAlbum(self.outputURL!.path, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
			}
		})
	}
	
	@objc func video(videoPath: String, didFinishSavingWithError error: NSError, contextInfo info: UnsafeMutableRawPointer) {
		cleanUpDocumentDirectory()
	}
	
	private func cleanUpDocumentDirectory() {
		do {
			try FileManager.default.removeItem(at: recordURL)
			guard let outputURL = outputURL else { return }
			try FileManager.default.removeItem(at: outputURL)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if rangeSlider.isPresented {
			rangeSlider.touchesBegan(touches, with: event)
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if rangeSlider.isPresented {
			rangeSlider.touchesMoved(touches, with: event)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		rangeSlider.touchesEnded(touches, with: event)
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.34, .present)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.33, .dismiss)
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
