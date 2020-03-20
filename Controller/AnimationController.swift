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
		
		// use ease in out
		
		
//		guard let from = transitionContext.viewController(forKey: .from) as? PlayerController, let to = transitionContext.viewController(forKey: .to) as? ViewController else { return }
//
//		let size = CGSize(width: 49.5, height: 48.5)
//		let duration = transitionDuration(using: transitionContext)
//		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: -1, options: .curveEaseOut, animations: {
//			viewToAnimate.frame.size = size
//			viewToAnimate.center = to.exposurePointView.center
//			to.blurEffectView.alpha = 0
//			to.view.alpha = 1
//		})
//
//		UIView.animate(withDuration: 0.16, delay: duration/1.35, options: .curveEaseOut, animations: {
//			viewToAnimate.alpha = 0
//		}) { (_) in
//			transitionContext.completeTransition(true)
//		}
//
//		UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
//			viewToAnimate.layer.cornerRadius = (size.width+size.height)/4
//		}.startAnimation()
	}
	
	func presentAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		guard let from = transitionContext.viewController(forKey: .from) as? ViewController, let to = transitionContext.viewController(forKey: .to) as? PlayerController else { return }
		
		viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width/2, y: -viewToAnimate.frame.height/2).scaledBy(x: 0.1, y: 0.1).rotated(by: .pi/6)
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
			from.view.alpha = 0.15
			to.blurEffectView.alpha = 0
			viewToAnimate.transform = CGAffineTransform.identity
		}) { (_) in
			transitionContext.completeTransition(true)
		}
	}
}
