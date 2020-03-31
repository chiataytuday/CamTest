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
	
	private var fileURL: URL!
	private var btnStackView: UIStackView!
	private var playerLayer: AVPlayerLayer!
	private var playerItem: AVPlayerItem!
	var queuePlayer: AVQueuePlayer!
	var timer: Timer?
	
	private let exportButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Save", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.setTitleColor(.systemGray, for: .normal)
		button.imageEdgeInsets.left = -8
		button.titleEdgeInsets.right = -8
		button.backgroundColor = .black
		button.tintColor = Colors.buttonLabel
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let backButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.tintColor = Colors.backIcon
		button.backgroundColor = .black
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let trimButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "scissors"), for: .normal)
		button.tintColor = Colors.backIcon
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
	

	override func viewDidLayoutSubviews() {
		exportButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 16.5)
		backButton.roundCorners(corners: [.topRight, .bottomRight], radius: 16.5)
	}
	
	override func viewDidLoad() {
		transitioningDelegate = self
		super.viewDidLoad()
		view.clipsToBounds = true
		view.backgroundColor = .black
	}
	
	deinit {
		print("OS deinits PlayerController: NO memory leaks/retain cycles")
	}
	
	private func setupInterface() {
		exportButton.addTarget(self, action: #selector(buttonDown(sender:)), for: .touchDown)
		exportButton.addTarget(self, action: #selector(buttonUpOutside(sender:)), for: .touchUpOutside)
		exportButton.addTarget(self, action: #selector(saveButtonUpInside(sender:)), for: .touchUpInside)
		NSLayoutConstraint.activate([
			exportButton.widthAnchor.constraint(equalToConstant: 100),
			exportButton.heightAnchor.constraint(equalToConstant: 48),
		])
		
		backButton.addTarget(self, action: #selector(buttonDown(sender:)), for: .touchDown)
		backButton.addTarget(self, action: #selector(buttonUpOutside(sender:)), for: .touchUpOutside)
		backButton.addTarget(self, action: #selector(backButtonUpInside(sender:)), for: .touchUpInside)
		NSLayoutConstraint.activate([
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 48)
		])
		
		trimButton.addTarget(self, action: #selector(trimButtonDown(sender:)), for: .touchDown)
		NSLayoutConstraint.activate([
			trimButton.widthAnchor.constraint(equalToConstant: 50),
			trimButton.heightAnchor.constraint(equalToConstant: 48)
		])
		
		btnStackView = UIStackView(arrangedSubviews: [exportButton, trimButton, backButton])
		btnStackView.translatesAutoresizingMaskIntoConstraints = false
		btnStackView.alignment = .center
		btnStackView.distribution = .fillProportionally
		btnStackView.spacing = -1
		view.addSubview(btnStackView)
		NSLayoutConstraint.activate([
			btnStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			btnStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
		])
		
		rangeSlider = RangeSlider(frame: CGRect(x: view.center.x, y: view.frame.height - 5, width: view.frame.width - 60, height: 30))
		rangeSlider.alpha = 0
		view.addSubview(rangeSlider)
		
		blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	var rangeSlider: RangeSlider!
	
	public func setupPlayer(_ url: URL, handler: @escaping (Bool) -> ()) {
		self.fileURL = url
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
		setupInterface()
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
		if rangeSlider.isPresented {
			trimButton.backgroundColor = Colors.buttonUp
			UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
				self.btnStackView.transform = CGAffineTransform(translationX: 0, y: -45)
				self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: -45)
			})
			UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
				self.rangeSlider.alpha = 1
			}.startAnimation()
		} else {
			trimButton.backgroundColor = .black
			UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
				self.btnStackView.transform = CGAffineTransform(translationX: 0, y: 0)
				self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: 0)
			})
			UIViewPropertyAnimator(duration: 0.075, curve: .easeIn) {
				self.rangeSlider.alpha = 0
			}.startAnimation()
		}
	}
	
	@objc private func buttonDown(sender: UIButton) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.view.layer.cornerRadius = 20
			sender.backgroundColor = Colors.buttonUp
		})
	}
	
	@objc private func buttonUpOutside(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.view.transform = CGAffineTransform.identity
			self.view.layer.cornerRadius = 0
			sender.backgroundColor = .black
		})
	}
	
	
	@objc private func saveButtonUpInside(sender: UIButton) {
		saveVideoToLibrary()
		backButtonUpInside(sender: sender)
	}
	
	private func saveVideoToLibrary() {
		let asset = AVAsset(url: fileURL)
		let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
		let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("outp").appendingPathExtension("mp4")
		exportSession?.outputURL = outputURL
		exportSession?.outputFileType = .mp4
		let range = CMTimeRange(start: rangeSlider.begin.time!, end: rangeSlider.end.time!)
		exportSession?.timeRange = range
		exportSession?.exportAsynchronously(completionHandler: {
			if exportSession?.status == .completed {
				print("\(outputURL.path) export completed")
				UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, self, #selector(self.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
			}
		})
	}
	
	private func removeVideoAtPath() {
		do {
			try FileManager.default.removeItem(at: fileURL)
			print("\(fileURL.path) removed")
		} catch {
			print(error.localizedDescription)
		}
	}
	
	@objc func video(videoPath: String, didFinishSavingWithError error: NSError, contextInfo info: UnsafeMutableRawPointer) {
		print("\(videoPath) saved to library")
		removeVideoAtPath()
	}
	
	
	@objc private func backButtonUpInside(sender: UIButton) {
		buttonUpOutside(sender: sender)
		UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
			self.blurEffectView.alpha = 1
		})
		queuePlayer.pause()
		observer?.invalidate()
		dismiss(animated: true, completion: nil)
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
		return AnimationController(0.34, .dismiss)
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
