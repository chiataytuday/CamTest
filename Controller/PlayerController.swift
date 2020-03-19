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
	
	let exportButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Export", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.titleEdgeInsets.right = -8
		button.imageEdgeInsets.left = -8
		button.backgroundColor = .black
		button.tintColor = .white
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}()
	
	let backButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.tintColor = .systemGray2
		button.backgroundColor = .black
		return button
	}()
	
	let blurEffectView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
		let effectView = UIVisualEffectView(effect: blurEffect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		return effectView
	}()
	
	private let progressView: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .systemGray2
		bar.layer.cornerRadius = 0.25
		return bar
	}()

	override func viewDidLayoutSubviews() {
		exportButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 17.5)
		backButton.roundCorners(corners: [.topRight, .bottomRight], radius: 17.5)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupPlayer()
		setupView()
	}
	
	private func setupView() {
		view.clipsToBounds = true
		transitioningDelegate = self
		view.backgroundColor = .black
		
		view.addSubview(progressView)
		progressView.frame.origin.y = view.frame.height - 0.5
		
    blurEffectView.frame = view.bounds
    view.addSubview(blurEffectView)
		
		NSLayoutConstraint.activate([
			exportButton.widthAnchor.constraint(equalToConstant: 110),
			exportButton.heightAnchor.constraint(equalToConstant: 50),
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 50)
		])
		let stackView = UIStackView(arrangedSubviews: [exportButton, backButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .center
		stackView.distribution = .equalSpacing
		stackView.clipsToBounds = true
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35)
		])
		
//		let stackView = UIStackView(arrangedSubviews: [exportButton, backButton])
//		stackView.translatesAutoresizingMaskIntoConstraints = false
//		stackView.layer.cornerRadius = 20
//		stackView.clipsToBounds = true
//		view.addSubview(stackView)
//		NSLayoutConstraint.activate([
//			exportButton.widthAnchor.constraint(equalToConstant: 110),
//			exportButton.heightAnchor.constraint(equalToConstant: 50),
//			backButton.widthAnchor.constraint(equalToConstant: 50),
//			backButton.heightAnchor.constraint(equalToConstant: 50),
//			stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//		])
		
	}
	
	private func setupPlayer() {
		let item = AVPlayerItem(url: url)
		let queuePlayer = AVQueuePlayer(playerItem: item)
		looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
		let layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		layer.cornerRadius = 17.5
		layer.masksToBounds = true
		view.layer.addSublayer(layer)
		queuePlayer.play()
		
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
	}
	
	private var looper: AVPlayerLooper?
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.35, .present)
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
