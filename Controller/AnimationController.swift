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
		let duration = transitionDuration(using: transitionContext)
		(transitionContext.viewController(forKey: .to) as? ViewController)?.resetView(duration)
		
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
			viewToAnimate.transform = CGAffineTransform(translationX: 0, y: -viewToAnimate.frame.height)
		}) { _ in
			transitionContext.completeTransition(true)
		}
	}
	
	func presentAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		
		guard let viewController = transitionContext.viewController(forKey: .from) as? ViewController, let playerController = transitionContext.viewController(forKey: .to) as? PlayerController else { return }
		
		viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width/2, y: -viewToAnimate.frame.height/2).scaledBy(x: 0.2, y: 0.2).rotated(by: .pi/7)
		
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
			viewController.view.alpha = 0.15
			playerController.blurView.alpha = 0
			viewToAnimate.transform = CGAffineTransform.identity
		}) { _ in
			transitionContext.completeTransition(true)
		}
	}
}
