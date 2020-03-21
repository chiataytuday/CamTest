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
		let effect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
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
	}
	
	private func setupInterface() {
		// Buttons
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
		stackView.distribution = .equalSpacing
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
	
	@objc private func buttonTouchDown(sender: UIButton) {
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			sender.backgroundColor = .systemGray6
		}, completion: nil)
		
		if sender == backButton {
			UIViewPropertyAnimator(duration: 0.75, curve: .easeOut) {
				self.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.975, 0.975, 1)
			}.startAnimation()
		} else {
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
				sender.imageView?.transform = CGAffineTransform(translationX: 0, y: -50)
			}, completion: nil)
		}
	}
	
	@objc private func buttonTouchUpOutside(sender: UIButton) {
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform.identity
			self.layer.transform = CATransform3DIdentity
			sender.backgroundColor = .black
		}, completion: nil)
	}
	
	private func exportAction(_ status: PHAuthorizationStatus) {
		switch status {
			case .denied:
				if let url = URL(string: UIApplication.openSettingsURLString) {
					if UIApplication.shared.canOpenURL(url) {
						UIApplication.shared.open(url, options: [:], completionHandler: nil)
					}
				}
			case .authorized:
				print("ok")
			default:
				print("idk")
		}
	}
	
	@objc private func exportTouchUpInside(sender: UIButton) {
		buttonTouchUpOutside(sender: sender)
		
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			sender.imageView?.transform = CGAffineTransform(translationX: 0, y: 50)
		}, completion: nil)
//		UIView.transition(with: sender, duration: 0.08, options: .transitionCrossDissolve, animations: {
//			sender.setTitle("Saved", for: .normal)
//			sender.setImage(UIImage(systemName: "checkmark"), for: .normal)
//		}, completion: nil)
		
		let status = PHPhotoLibrary.authorizationStatus()
		if status == .notDetermined {
			PHPhotoLibrary.requestAuthorization { (status) in
				self.exportAction(status)
			}
		} else {
			exportAction(status)
		}
	}
	
	@objc private func backTouchUpInside(sender: UIButton) {
		buttonTouchUpOutside(sender: sender)
		UIView.animate(withDuration: 0.45, delay: 0, options: .curveEaseOut, animations: {
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
		return AnimationController(0.32, .dismiss)
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
