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
	
	init(_ text: String, _ position: CGPoint) {
		errorLabel.text = text
		errorLabel.sizeToFit()
		super.init(frame: errorLabel.frame.insetBy(dx: -16, dy: -8))
		backgroundColor = Colors.red
		layer.cornerRadius = frame.height/2
		center.x = position.x
		errorLabel.frame.origin.x += 16
		errorLabel.frame.origin.y += 8
		frame.origin.y = position.y
		addSubview(errorLabel)
		alpha = 0
	}
	
	func animate() {
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
