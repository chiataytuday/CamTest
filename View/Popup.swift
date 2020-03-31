//
//  Popup.swift
//  Flaneur
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Popup : UIView {
	
	private var isExpanded = false
	
	private let iconImageView: UIImageView = {
		let image = UIImage(systemName: "sun.max.fill")
		let imageView = UIImageView(image: image)
		imageView.tintColor = Colors.gray5
		return imageView
	}()
	
	private let numLabel: UILabel = {
		let label = UILabel()
		label.text = "0.0"
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = Colors.gray5
		label.lineBreakMode = .byClipping
		label.sizeToFit()
		return label
	}()
	
	init(_ center: CGPoint) {
		let contentRect = CGRect(x: 0, y: 0, width: iconImageView.frame.width + numLabel.frame.width + 5, height: iconImageView.frame.height)
		super.init(frame: contentRect.insetBy(dx: -16, dy: -7.25))
		numLabel.frame.origin.x = iconImageView.frame.width + 5
		for v in [iconImageView, numLabel] {
			v.frame.origin.x += 16
			v.center.y = self.center.y + 7.25
		}
		
		self.center = center
		backgroundColor = .black
		layer.cornerRadius = frame.height/2
		alpha = 0
		
		addSubview(iconImageView)
		addSubview(numLabel)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	typealias PopupFrame = (width: CGFloat, x: CGFloat)
	
	func setLabelDigit(_ value: CGFloat) {
		numLabel.text = "\(value)"
		numLabel.sizeToFit()
		
		if value < 0 && !isExpanded || value >= 0 && isExpanded {
			let args: PopupFrame = isExpanded ? (-10, 5) : (10, -5)
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
				self.frame.size.width += args.width
				self.frame.origin.x += args.x
			}, completion: nil)
			isExpanded = value < 0
		}
	}
	
	func setIconImage(_ image: UIImage) {
		iconImageView.image = image
	}
	
	func show() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 15)
			self.alpha = 1
		}, completion: nil)
	}
	
	func hide() {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform.identity
			self.alpha = 0
		}, completion: nil)
	}
}
