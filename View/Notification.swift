//
//  Notification.swift
//  Amble
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Notification : UIView {
	
	private let label: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = .white
		return label
	}()
	
	init(_ labelText: String, _ position: CGPoint) {
		label.text = labelText
		label.sizeToFit()
		let margin = CGPoint(x: 16, y: 8)
		super.init(frame: label.frame.insetBy(dx: -margin.x, dy: -margin.y))
		backgroundColor = .systemRed
		layer.cornerRadius = frame.height/2
		alpha = 0
		
		center.x = position.x
		frame.origin.y = position.y
		label.frame.origin.x += margin.x
		label.frame.origin.y += margin.y
		addSubview(label)
	}
	
	func show() {
		transform = CGAffineTransform(translationX: 0, y: 15)
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform.identity
			self.alpha = 1
		})

		UIView.animate(withDuration: 0.2, delay: 2, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 5)
			self.alpha = 0
		}) { _ in
			self.removeFromSuperview()
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
