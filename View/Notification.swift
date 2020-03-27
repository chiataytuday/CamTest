//
//  Notification.swift
//  Amble
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Notification: UIView {
	
	private let errorLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = .white
		return label
	}()
	
	init(_ text: String, _ location: CGPoint) {
		errorLabel.text = text
		errorLabel.sizeToFit()
		let inset = CGPoint(x: 16, y: 8)
		super.init(frame: errorLabel.frame.insetBy(dx: -inset.x, dy: -inset.y))
		
		backgroundColor = Colors.red
		layer.cornerRadius = frame.height/2
		alpha = 0
		
		center.x = location.x
		frame.origin.y = location.y
		errorLabel.frame.origin.x += inset.x
		errorLabel.frame.origin.y += inset.y
		addSubview(errorLabel)
	}
	
	func show() {
		transform = CGAffineTransform(translationX: 0, y: 15)
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform.identity
			self.alpha = 1
		})
		
		UIView.animate(withDuration: 0.3, delay: 2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 10)
			self.alpha = 0
		}) { _ in
			self.removeFromSuperview()
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
