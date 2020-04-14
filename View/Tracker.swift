//
//  Tracker.swift
//  Flaneur
//
//  Created by debavlad on 14.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Tracker: UIView {
	
	let maxNumber: Int
	
	private let numLabel: UILabel = {
		let label = UILabel()
		label.text = "0"
		label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .light)
		label.textColor = .label
		label.sizeToFit()
		return label
	}()
	
	private let filledView: UIView = {
		let view = UIView()
		view.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.5)
		return view
	}()
	
	init(center: CGPoint, maxNumber: Int) {
		self.maxNumber = maxNumber
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 25)))
		self.center = center
		backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
		layer.cornerRadius = 10
		clipsToBounds = true
		alpha = 0
		
		filledView.frame.size.height = frame.size.height
		addSubview(filledView)
		numLabel.center = CGPoint(x: frame.width/2, y: frame.height/2)
		addSubview(numLabel)
	}
	
	func setLabel(number: Int) {
		guard number <= maxNumber else { return }
		numLabel.text = "\(number)"
		numLabel.sizeToFit()
		numLabel.center.x = frame.width/2
		
		let width = frame.width/CGFloat(maxNumber)*CGFloat(number)
		UIViewPropertyAnimator(duration: 0.12, curve: .easeOut) {
			self.filledView.frame.size.width = width
			self.filledView.frame.origin.x = 0
		}.startAnimation()
	}
	
	func fadeIn() {
		transform = CGAffineTransform(translationX: 0, y: 15)
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [], animations: {
			self.transform = .identity
			self.alpha = 1
		})
	}
	
	func fadeOut() {
		UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
			self.alpha = 0
		}) { _ in
			self.setLabel(number: 0)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
