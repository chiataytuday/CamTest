//
//  Notification.swift
//  Flaneur
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Notification : UIView {
	
	private let infoLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = .white
		return label
	}()
	
	init(text: String, color: UIColor = .black) {
		infoLabel.text = text
		infoLabel.sizeToFit()
		
		let margin: (x: CGFloat, y: CGFloat) = (16, 8)
		super.init(frame: infoLabel.frame.insetBy(dx: -margin.x, dy: -margin.y))
		infoLabel.frame.origin.x += margin.x
		infoLabel.frame.origin.y += margin.y
		addSubview(infoLabel)
		
		backgroundColor = color
		layer.cornerRadius = frame.height/2
		alpha = 0
	}
	
	func present(for duration: TimeInterval) {
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
