//
//  MovablePoint.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class MovablePoint : UIImageView {
	
	var camera: Camera?
	var offset: CGPoint?
	
	init() {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		super.init(image: image)
		isUserInteractionEnabled = true
		tintColor = .systemYellow
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		let t = touches.first!.location(in: superview!)
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		})
		offset = CGPoint(x: t.x - frame.origin.x, y: t.y - frame.origin.y)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let t = touches.first!.location(in: superview!)
		if let offset = offset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.frame.origin = CGPoint(x: t.x - offset.x, y: t.y - offset.y)
			}.startAnimation()
			camera?.setExposure(t, .autoExpose)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		offset = nil
		var point: CGPoint?
		if frame.maxY > superview!.frame.height - 80 {
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
				self.center.y = self.superview!.frame.height - self.frame.height/2 - 85
			})
			point = center
		}
		
		if let p = point {
			camera?.setExposure(p, User.shared.exposureMode)
		} else {
			camera?.setExposure(User.shared.exposureMode)
		}
		
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.transform = CGAffineTransform.identity
		})
	}
}
