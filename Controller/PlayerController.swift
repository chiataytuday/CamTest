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
	
	let blurEffectView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
		let effectView = UIVisualEffectView(effect: blurEffect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		return effectView
	}()
	
	private let progressView: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .white
		bar.layer.cornerRadius = 0.25
		return bar
	}()

	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupPlayer()
		setupView()
	}
	
	private func setupView() {
		view.layer.cornerRadius = 15
		view.clipsToBounds = true
		transitioningDelegate = self
		
		view.addSubview(progressView)
		progressView.frame.origin.y = view.frame.height - 0.5
		
    blurEffectView.frame = view.bounds
    view.addSubview(blurEffectView)
	}
	
	private func setupPlayer() {
		let item = AVPlayerItem(url: url)
		let queuePlayer = AVQueuePlayer(playerItem: item)
		looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
		let layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(layer)
		queuePlayer.play()
		
		queuePlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(USEC_PER_SEC)), queue: .main) { (time) in
			guard time.seconds > 0, item.duration.seconds > 0 else {
				self.progressView.frame.size.width = 0
				return
			}
			let duration = CGFloat(time.seconds/item.duration.seconds)
			UIViewPropertyAnimator(duration: 0.09, curve: .linear) {
				self.progressView.frame.size.width = duration * self.view.frame.width
			}.startAnimation()
		}
	}
	
	private var looper: AVPlayerLooper?
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.35, .present)
	}
}
