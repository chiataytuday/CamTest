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
		exportButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
		exportButton.addTarget(self, action: #selector(buttonTouchUpOutside(sender:)), for: .touchUpOutside)
		exportButton.addTarget(self, action: #selector(exportTouchUpInside(sender:)), for: .touchUpInside)
		NSLayoutConstraint.activate([
			exportButton.widthAnchor.constraint(equalToConstant: 100),
			exportButton.heightAnchor.constraint(equalToConstant: 48),
		])
		
		backButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
		backButton.addTarget(self, action: #selector(buttonTouchUpOutside(sender:)), for: .touchUpOutside)
		backButton.addTarget(self, action: #selector(backTouchUpInside(sender:)), for: .touchUpInside)
		NSLayoutConstraint.activate([
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 48)
		])
		
		trimButton.addTarget(self, action: #selector(trimTouchDown(sender:)), for: .touchDown)
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
		
		rangeSlider = RangeSlider(frame: CGRect(x: view.center.x, y: view.frame.height - 10, width: view.frame.width - 60, height: 20))
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
	
	@objc private func trimTouchDown(sender: UIButton) {
		rangeSlider.isPresented = !rangeSlider.isPresented
		
		if rangeSlider.isPresented {
			trimButton.backgroundColor = Colors.buttonUp
			UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
				self.btnStackView.transform = CGAffineTransform(translationX: 0, y: -30)
				self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: -30)
			})
			UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
				self.rangeSlider.alpha = 1
			}.startAnimation()
		} else {
			trimButton.backgroundColor = .black
			UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
				self.btnStackView.transform = CGAffineTransform(translationX: 0, y: 0)
				self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: 0)
			})
			UIViewPropertyAnimator(duration: 0.075, curve: .easeIn) {
				self.rangeSlider.alpha = 0
			}.startAnimation()
		}
	}
	
	@objc private func buttonTouchDown(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.btnStackView.transform = self.btnStackView.transform.scaledBy(x: 0.95, y: 0.95)
			self.rangeSlider.transform = self.rangeSlider.transform.scaledBy(x: 0.95, y: 0.95)
			sender.backgroundColor = Colors.buttonUp
		})
		
		UIViewPropertyAnimator(duration: 0.7, curve: .easeOut) {
			self.playerLayer.transform = CATransform3DScale(CATransform3DIdentity, 0.975, 0.975, 1)
		}.startAnimation()
	}
	
	@objc private func buttonTouchUpOutside(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
//			self.stackView.transform = self.stackView.transform.scaledBy(x: 1.05, y: 1.05)
//			self.rangeSlider.transform = self.rangeSlider.transform.scaledBy(x: 1.05, y: 1.05)
			self.playerLayer.transform = CATransform3DIdentity
			sender.backgroundColor = .black
		})
	}
	
	@objc private func exportTouchUpInside(sender: UIButton) {
		let videoAsset = AVAsset(url: fileURL)
		let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset1920x1080)
		let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let outputURL = url.appendingPathComponent("ou1").appendingPathExtension("mp4")
		do {
			try FileManager.default.removeItem(at: outputURL)
		} catch {}
		exportSession?.outputURL = outputURL
		exportSession?.outputFileType = .mp4
		let range = CMTimeRange(start: rangeSlider.begin.time!, end: rangeSlider.end.time!)
		exportSession?.timeRange = range
		exportSession?.exportAsynchronously(completionHandler: {
			if exportSession!.status == AVAssetExportSession.Status.completed {
				UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path, nil, nil, nil)
			}
		})
		backTouchUpInside(sender: sender)
	}
	
	@objc private func backTouchUpInside(sender: UIButton) {
		buttonTouchUpOutside(sender: sender)
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
		return AnimationController(0.35, .present)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.35, .dismiss)
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
