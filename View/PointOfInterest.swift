//
//  PointOfInterest.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class PointOfInterest: UIImageView {
	
	var cam: Camera?
	var offset: CGPoint?
	
	init() {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		super.init(image: image)
		isUserInteractionEnabled = true
		tintColor = Colors.yellow
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: superview!) else { return }
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		})
		offset = CGPoint(x: touch.x - frame.origin.x, y: touch.y - frame.origin.y)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: superview!) else { return }
		if let offset = offset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			cam?.setExposure(touch, .autoExpose)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		var point: CGPoint?
		if frame.maxY > superview!.frame.height - 80 {
			UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
				self.center.y = self.superview!.frame.height - 85 - self.frame.height/2
			})
			point = center
		}
		offset = nil
		if let point = point {
			cam?.setExposure(point, Settings.shared.exposureMode)
		} else {
			cam?.setExposure(Settings.shared.exposureMode)
		}
		
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform.identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
