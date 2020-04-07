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
	
	private let imageView: UIImageView = {
		let image = UIImage(systemName: "sun.max.fill")
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemGray
		return imageView
	}()
	
	private let valueLabel: UILabel = {
		let label = UILabel()
		label.text = "0.0"
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = .systemGray
		label.lineBreakMode = .byClipping
		label.sizeToFit()
		return label
	}()
	
	
	init() {
		valueLabel.frame.origin.x = imageView.frame.width + 5
		let contentRect = CGRect(origin: .zero, size: CGSize(width: imageView.frame.width + 5 + valueLabel.frame.width, height: imageView.frame.height))
		super.init(frame: contentRect.insetBy(dx: -16, dy: -7.25))
		
		// Compensate insets by moving subviews
		for subview in [imageView, valueLabel] {
			subview.frame.origin.x += 16
			subview.center.y = center.y + 7.25
		}
		addSubview(imageView); addSubview(valueLabel)
		
		backgroundColor = .systemBackground
		layer.cornerRadius = frame.height/2
		alpha = 0
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	typealias PopupFrame = (width: CGFloat, x: CGFloat)
	
	func setValue(_ value: CGFloat) {
		valueLabel.text = "\(value)"
		valueLabel.sizeToFit()
		
		if value < 0 && !isExpanded || value >= 0 && isExpanded {
			let args: PopupFrame = isExpanded ? (-10, 5) : (10, -5)
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
				self.frame.size.width += args.width
				self.frame.origin.x += args.x
			})
			isExpanded = value < 0
		}
	}
	
	func setImage(_ image: UIImage) {
		imageView.image = image
	}
	
	func show() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 15)
			self.alpha = 1
		})
	}
	
	func hide() {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = .identity
			self.alpha = 0
		})
	}
}
