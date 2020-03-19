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
		(transitionContext.viewController(forKey: .to) as! ViewController).resetControls()
		(transitionContext.viewController(forKey: .from) as! PlayerController).blurEffectView.alpha = 1
		(transitionContext.viewController(forKey: .from) as! PlayerController).view.clipsToBounds = false
		(transitionContext.viewController(forKey: .to) as! ViewController).blurEffectView.alpha = 1
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			transitionContext.viewController(forKey: .to)!.view.alpha = 1
//			viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width, y: -viewToAnimate.frame.height/1.75).scaledBy(x: 0.5, y: 0.5).rotated(by: -.pi/5)
			viewToAnimate.transform = CGAffineTransform(translationX: 0, y: -viewToAnimate.frame.width*2).scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/5)
		}) { (_) in
			transitionContext.completeTransition(true)
		}
		
		UIViewPropertyAnimator(duration: duration/2, curve: .easeOut) {
			(transitionContext.viewController(forKey: .to) as! ViewController).blurEffectView.alpha = 0
		}.startAnimation()
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
