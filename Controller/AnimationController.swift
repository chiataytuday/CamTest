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
				print("Implement this")
		}
	}
	
	func presentAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		viewToAnimate.clipsToBounds = true
		viewToAnimate.transform = CGAffineTransform(translationX: 0, y: 250).scaledBy(x: 0.1, y: 0.1)
		
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 3, options: .curveEaseOut, animations: {
			transitionContext.viewController(forKey: .from)!.view.alpha = 0.2
			viewToAnimate.transform = CGAffineTransform(scaleX: 1, y: 1)
		}) { (_) in
			transitionContext.completeTransition(true)
		}
		
		UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
			(transitionContext.viewController(forKey: .to) as! PlayerController).blurEffectView.alpha = 0
		}.startAnimation()
	}
}
