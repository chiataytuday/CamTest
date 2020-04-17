//
//  AnimationController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

final class AnimationController : NSObject {
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
		
		guard let cameraController = transitionContext.viewController(forKey: .to) as? CameraController else { return }
		let duration = transitionDuration(using: transitionContext)
		cameraController.resetView()
		
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: { [weak viewToAnimate, weak cameraController] in
			cameraController?.blurEffectView.alpha = 0
			cameraController?.view.alpha = 1
			viewToAnimate?.transform = CGAffineTransform(translationX: 0, y: -viewToAnimate!.frame.height)
		}) { _ in
			transitionContext.completeTransition(true)
		}
	}
	
	func presentAnimation(with transitionContext: UIViewControllerContextTransitioning, viewToAnimate: UIView) {
		
		guard let cameraController = transitionContext.viewController(forKey: .from) as? CameraController else { return }
		
		viewToAnimate.transform = CGAffineTransform(translationX: viewToAnimate.frame.width/2, y: -viewToAnimate.frame.height/2).scaledBy(x: 0.05, y: 0.05).rotated(by: .pi/7)
		let duration = transitionDuration(using: transitionContext)
		UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: { [weak viewToAnimate, weak cameraController] in
			cameraController?.blurEffectView.alpha = 1
			cameraController?.view.alpha = 0.3
			viewToAnimate?.transform = .identity
		}) { _ in
			transitionContext.completeTransition(true)
		}
	}
}
