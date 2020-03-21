//
//  AnimationController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class AnimationController : NSObject {
	private let animationDuration: Double
	private let animationType: AnimationType
	
	enum AnimationType {
		case present
		case dismiss
	}
	
	init(_ animationDuration: Double, _ animationType: AnimationType) {
		self.animationDuration = animationDuration
		self.animationType = animationType
	}
}

extension AnimationController : UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return TimeInterval(exactly: animationDuration) ?? 0
	}
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let toViewController = transitionContext.viewController(forKey: .to),
			let fromViewController = transitionContext.viewController(forKey: .from) else {
				transitionContext.completeTransition(false)
				return
		}
		switch animationType {
			case .present:
				transitionContext.containerView.addSubview(toViewController.view)
				presentAnimation(with: transitionContext, viewToAnimate: toViewController.view)
			case .dismiss:
				transitionContext.containerView.addSubview(fromViewController.view)
				dismissAnimation(with: transitionContext, viewToAnimate: fromViewController.view)
		}
	}
	
	func dismissAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		guard let viewController = transitionContext.viewController(forKey: .to) as? ViewController else { return }
		
		viewController.resetControls()
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
			viewToAnimate.transform = CGAffineTransform(translationX: 0, y: viewToAnimate.frame.height)
		}, completion: nil)
		
		UIView.animate(withDuration: duration * 0.8, delay: 0.01, options: .curveEaseOut, animations: {
			viewController.view.alpha = 1
			viewController.blurEffectView.alpha = 0
		}) { _ in
			transitionContext.completeTransition(true)
		}
	}
	
	func presentAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		guard let viewController = transitionContext.viewController(forKey: .from) as? ViewController, let playerController = transitionContext.viewController(forKey: .to) as? PlayerController else { return }
		
		viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width/2, y: -viewToAnimate.frame.height/2).scaledBy(x: 0.1, y: 0.1).rotated(by: .pi/6)
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
			viewController.view.alpha = 0.15
			playerController.blurEffectView.alpha = 0
			viewToAnimate.transform = CGAffineTransform.identity
		}) { _ in
			transitionContext.completeTransition(true)
		}
		
//		guard let from = transitionContext.viewController(forKey: .from) as? ViewController, let to = transitionContext.viewController(forKey: .to) as? PlayerController else { return }
//
//		viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width/2, y: -viewToAnimate.frame.height/2).scaledBy(x: 0.1, y: 0.1).rotated(by: .pi/6)
//		let duration = transitionDuration(using: transitionContext)
//		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
//			from.view.alpha = 0.15
//			to.blurEffectView.alpha = 0
//			viewToAnimate.transform = CGAffineTransform.identity
//		}) { (_) in
//			transitionContext.completeTransition(true)
//		}
	}
}
