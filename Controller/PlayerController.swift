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
	
	private var url: URL!
	private var stackView: UIStackView!
//	private var looper: AVPlayerLooper?
	private var layer: AVPlayerLayer!
	private var item: AVPlayerItem!
	var queuePlayer: AVQueuePlayer!
	var timer: Timer?
	
	private let exportButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Export", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 16.5, weight: .regular)
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
	
	let blurView: UIVisualEffectView = {
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
			exportButton.widthAnchor.constraint(equalToConstant: 110),
			exportButton.heightAnchor.constraint(equalToConstant: 50),
		])
		
		backButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
		backButton.addTarget(self, action: #selector(buttonTouchUpOutside(sender:)), for: .touchUpOutside)
		backButton.addTarget(self, action: #selector(backTouchUpInside(sender:)), for: .touchUpInside)
		NSLayoutConstraint.activate([
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 50)
		])
		
		trimButton.addTarget(self, action: #selector(trimTouchDown(sender:)), for: .touchDown)
		NSLayoutConstraint.activate([
			trimButton.widthAnchor.constraint(equalToConstant: 50),
			trimButton.heightAnchor.constraint(equalToConstant: 50)
		])
		
		stackView = UIStackView(arrangedSubviews: [exportButton, trimButton, backButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .center
		stackView.distribution = .fillProportionally
		stackView.spacing = -1
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
		])
		
		
		rangeSlider = RangeSlider(frame: CGRect(x: view.center.x, y: view.frame.height + 15, width: view.frame.width - 60, height: 20))
		view.addSubview(rangeSlider)
		
		
		blurView.frame = view.bounds
		view.addSubview(blurView)
	}
	
	var rangeSlider: RangeSlider!
	
	@objc func didPlayToEndTime() {
		print("0")
	}
	
	public func setupPlayer(_ url: URL, handler: @escaping (Bool) -> ()) {
		self.url = url
		item = AVPlayerItem(url: url)
		queuePlayer = AVQueuePlayer(playerItem: item)
		queuePlayer.actionAtItemEnd = .pause
		
		NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] (_) in
			self?.queuePlayer.seek(to: self!.rangeSlider.begin.time!, toleranceBefore: .zero, toleranceAfter: .zero)
			self?.queuePlayer.play()
		}
		
		layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(layer)
		setupInterface()
		timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (t) in
			self?.observer?.invalidate()
			t.invalidate()
			handler(false)
		})
		observer = item.observe(\.status, options: [.new], changeHandler: { [weak self] (item, change) in
			if item.status == .readyToPlay {
				self?.rangeSlider.videoPlayer = self?.queuePlayer
				self?.rangeSlider.begin.update!()
				self?.rangeSlider.end.update!()
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
		let args: (CGFloat, CGFloat, UIColor) = rangeSlider.isPresented ? (-30, -55, Colors.buttonUp) : (0, 0, .black)
		trimButton.backgroundColor = args.2
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(translationX: 0, y: args.0)
			self.rangeSlider.transform = CGAffineTransform(translationX: 0, y: args.1)
		})
	}
	
	@objc private func buttonTouchDown(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = self.stackView.transform.scaledBy(x: 0.95, y: 0.95)
			self.rangeSlider.transform = self.rangeSlider.transform.scaledBy(x: 0.95, y: 0.95)
			sender.backgroundColor = Colors.buttonUp
		})
		
		UIViewPropertyAnimator(duration: 0.7, curve: .easeOut) {
			self.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.975, 0.975, 1)
		}.startAnimation()
	}
	
	@objc private func buttonTouchUpOutside(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
//			self.stackView.transform = self.stackView.transform.scaledBy(x: 1.05, y: 1.05)
//			self.rangeSlider.transform = self.rangeSlider.transform.scaledBy(x: 1.05, y: 1.05)
			self.layer.transform = CATransform3DIdentity
			sender.backgroundColor = .black
		})
	}
	
	@objc private func exportTouchUpInside(sender: UIButton) {
		let videoAsset = AVAsset(url: url)
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
			self.blurView.alpha = 1
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
