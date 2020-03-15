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
	var blurEffectView: UIVisualEffectView!
	
	private let saveButton: UIButton = {
		let button = UIButton(type: .custom)
		button.layer.cornerRadius = 21
		button.backgroundColor = .white
		button.setTitle("To camera roll", for: .normal)
		button.setTitleColor(.systemGray6, for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 20 , weight: .regular)
		button.setImage(UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
		button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
		button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
		button.tintColor = .systemGray6
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addShadow(2.5, 0.15)
		return button
	}()
	
	private let progressView: UIView = {
		let view = UIView()
		view.backgroundColor = .white
		return view
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.layer.cornerRadius = 6
		view.clipsToBounds = true
		transitioningDelegate = self
		
		let item = AVPlayerItem(url: url)
		let player = AVPlayer(playerItem: item)
		player.actionAtItemEnd = .none
		NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
		player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(USEC_PER_SEC)), queue: .main) { (time) in
			guard time.seconds > 0, item.duration.seconds > 0 else {
				self.progressView.frame.size.width = 0
				return
			}
			let duration = CGFloat(time.seconds/item.duration.seconds)
			UIViewPropertyAnimator(duration: 0.09, curve: .linear) {
				self.progressView.frame.size.width = duration * self.view.frame.width
			}.startAnimation()
			
		}
		
		
		let layer = AVPlayerLayer(player: player)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(layer)
		player.play()
		
		view.addSubview(saveButton)
		NSLayoutConstraint.activate([
			saveButton.heightAnchor.constraint(equalToConstant: 52),
			saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
			saveButton.widthAnchor.constraint(equalToConstant: 220),
			saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		progressView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 3)
		progressView.layer.cornerRadius = 1.5
		progressView.addShadow(2.5, 0.15)
		view.addSubview(progressView)
		
		let blurEffect = UIBlurEffect(style: .regular)
    blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = self.view.bounds
    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(blurEffectView)
	}
	
	@objc private func playerItemDidReachEnd(notification: Notification) {
		if let playerItem = notification.object as? AVPlayerItem {
			playerItem.seek(to: .zero, completionHandler: nil)
		}
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.6, .present)
	}
}
