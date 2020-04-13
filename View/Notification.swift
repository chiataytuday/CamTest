//
//  Notification.swift
//  Flaneur
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Notification: UIView {
	
	let label: UILabel = {
		let lbl = UILabel()
		lbl.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		lbl.textColor = .white
		return lbl
	}()
	
	init(text: String) {
		label.text = text
		label.sizeToFit()
		
		let padding: (x: CGFloat, y: CGFloat) = (16, 8)
		super.init(frame: label.frame.insetBy(dx: -padding.x, dy: -padding.y))
		label.frame.origin.x += padding.x
		label.frame.origin.y += padding.y
		addSubview(label)
		
		backgroundColor = .systemRed
		layer.cornerRadius = frame.height/2
		alpha = 0
	}
	
	func show(for duration: TimeInterval) {
		transform = CGAffineTransform(translationX: 0, y: 15)
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [], animations: {
			self.transform = .identity
			self.alpha = 1
		})

		UIView.animate(withDuration: 0.25, delay: duration, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
			self.alpha = 0
		}) { _ in
			self.removeFromSuperview()
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
