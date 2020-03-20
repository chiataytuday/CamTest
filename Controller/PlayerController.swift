//
//  PlayerController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerController: UIViewController {
	
	var url: URL!
	var looper: AVPlayerLooper?
	var stackView: UIStackView!
	var layer: AVPlayerLayer!
	
	let exportButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Export", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.setTitleColor(.systemGray, for: .normal)
		button.imageEdgeInsets.left = -8
		button.titleEdgeInsets.right = -8
		button.backgroundColor = .black
		button.tintColor = .systemGray
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	let backButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.tintColor = .systemGray3
		button.backgroundColor = .black
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	let blurEffectView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: UIBlurEffect.Style.regular)
		let view = UIVisualEffectView(effect: effect)
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.alpha = 1
		return view
	}()
	
	let overlayView: UIView = {
		let view = UIView()
		view.backgroundColor = .systemRed
		view.alpha = 0
		return view
	}()
	
	private let progressView: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .systemGray2
		bar.layer.cornerRadius = 0.25
		return bar
	}()

	override func viewDidLayoutSubviews() {
		exportButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 15.5)
		backButton.roundCorners(corners: [.topRight, .bottomRight], radius: 15.5)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.clipsToBounds = true
		view.layer.cornerRadius = 17.5
		transitioningDelegate = self
		view.backgroundColor = .black
	}
	
	private func setupInterface() {
		// Buttons
		exportButton.addTarget(self, action: #selector(exportTouchDown), for: .touchDown)
		exportButton.addTarget(self, action: #selector(exportTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			exportButton.widthAnchor.constraint(equalToConstant: 110),
			exportButton.heightAnchor.constraint(equalToConstant: 50),
		])
		
		backButton.addTarget(self, action: #selector(backTouchDown), for: .touchDown)
		backButton.addTarget(self, action: #selector(backTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 50)
		])
		
		stackView = UIStackView(arrangedSubviews: [exportButton, backButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .center
		stackView.distribution = .equalSpacing
		stackView.spacing = -5
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35)
		])
		
		// Timeline and blur
		view.addSubview(progressView)
		progressView.frame.origin.y = view.frame.height - 0.5
		
    blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
		
		view.addSubview(overlayView)
		overlayView.frame = view.frame
	}
	
	public func setupPlayer(_ url: URL, handler: @escaping () -> ()) {
		let item = AVPlayerItem(url: url)
		let queuePlayer = AVQueuePlayer(playerItem: item)
		looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
		layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		layer.cornerRadius = 17.5
		layer.masksToBounds = true
		view.layer.addSublayer(layer)
		queuePlayer.play()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
			handler()
			self.setupInterface()
		}
	}
	
//		queuePlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(USEC_PER_SEC)), queue: .main) { (time) in
//			guard time.seconds > 0, item.duration.seconds > 0 else {
//				self.progressView.frame.size.width = 0
//				return
//			}
//			let duration = CGFloat(time.seconds/item.duration.seconds)
//			UIViewPropertyAnimator(duration: 0.09, curve: .linear) {
//				self.progressView.frame.size.width = duration * self.view.frame.width
//			}.startAnimation()
//		}
//	}
	
	@objc private func exportTouchDown() {
		UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.exportButton.backgroundColor = .systemGray6
		}, completion: nil)
	}
	
	@objc private func exportTouchUp() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform  = CGAffineTransform.identity
			self.exportButton.backgroundColor = .black
		}, completion: nil)
	}
	
	@objc private func backTouchDown() {
		UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.backButton.backgroundColor = .systemGray6
		}, completion: nil)
		
		UIViewPropertyAnimator(duration: 0.75, curve: .easeOut) {
			self.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.975, 0.975, 1)
		}.startAnimation()
	}
	
	@objc private func backTouchUp() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform  = CGAffineTransform.identity
			self.blurEffectView.alpha = 1
		}, completion: nil)
		dismiss(animated: true, completion: nil)
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.4, .present)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.4, .dismiss)
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
