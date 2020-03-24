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
	private var looper: AVPlayerLooper?
	private var layer: AVPlayerLayer!
	private var item: AVPlayerItem!
	var queuePlayer: AVQueuePlayer!
	
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
		button.tintColor = .systemGray
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	private let backButton: UIButton = {
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
		super.viewDidLoad()
		view.clipsToBounds = true
		transitioningDelegate = self
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
		
		stackView = UIStackView(arrangedSubviews: [exportButton, backButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .center
		stackView.distribution = .fillProportionally
		stackView.spacing = -1
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
		])
		
    blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	public func setupPlayer(_ url: URL, handler: @escaping () -> ()) {
		self.url = url
		item = AVPlayerItem(url: url)
		queuePlayer = AVQueuePlayer(playerItem: item)
		looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
		layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(layer)
		queuePlayer.play()

		self.setupInterface()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
			handler()
		}
	}
	
	
	@objc private func buttonTouchDown(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			sender.backgroundColor = .systemGray6
		}, completion: nil)
		
		UIViewPropertyAnimator(duration: 0.7, curve: .easeOut) {
			self.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.975, 0.975, 1)
		}.startAnimation()
	}
	
	@objc private func buttonTouchUpOutside(sender: UIButton) {
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform.identity
			self.layer.transform = CATransform3DIdentity
			sender.backgroundColor = .black
		}, completion: nil)
	}
	
	@objc private func exportTouchUpInside(sender: UIButton) {
		DispatchQueue.global(qos: .background).async {
			UISaveVideoAtPathToSavedPhotosAlbum(self.url.path, nil, nil, nil)
		}
		backTouchUpInside(sender: sender)
	}
	
	@objc private func backTouchUpInside(sender: UIButton) {
		buttonTouchUpOutside(sender: sender)
		UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
			self.blurEffectView.alpha = 1
		}, completion: nil)
		Settings.shared.playedOpened = false
		queuePlayer.pause()
		dismiss(animated: true, completion: nil)
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
