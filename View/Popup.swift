//
//  Popup.swift
//  CamTest
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Popup: UIView {
	
	private var isExpanded = false
	
	private let imageView: UIImageView = {
		let image = UIImage(systemName: "sun.max.fill")
		let view = UIImageView(image: image)
		view.tintColor = Colors.popupContent
		return view
	}()
	
	private let valueLabel: UILabel = {
		let label = UILabel()
		label.text = "0.0"
		label.font = UIFont.systemFont(ofSize: 16.5, weight: .light)
		label.textColor = Colors.popupContent
		label.lineBreakMode = .byClipping
		label.sizeToFit()
		return label
	}()

	
	init(_ location: CGPoint) {
		let rect = CGRect(x: 0, y: 0, width: imageView.frame.width + valueLabel.frame.width + 5, height: imageView.frame.height)
		super.init(frame: rect.insetBy(dx: -16, dy: -7.25))
		
		valueLabel.frame.origin.x += imageView.frame.width + 5
		for el in [imageView, valueLabel] {
			el.frame.origin.x += 16
			el.center.y = center.y + 7.25
		}
		
		center = location
		backgroundColor = .black
		layer.cornerRadius = 17.5
		alpha = 0
		
		addSubview(imageView)
		addSubview(valueLabel)
	}
	
	func setLabel(_ value: CGFloat) {
		valueLabel.text = "\(value)"
		valueLabel.sizeToFit()
		
		if value < 0 && !isExpanded || value >= 0 && isExpanded {
			let args: (CGFloat, CGFloat) = isExpanded ? (-10, 5) : (10, -5)
			UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
				self.frame.size.width += args.0
				self.frame.origin.x += args.1
			})
			isExpanded = value < 0
		}
	}
	
	func setImage(_ image: UIImage) {
		imageView.image = image
	}
	
	func show() {
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 20)
			self.alpha = 1
		})
	}
	
	func hide() {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseIn, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform.identity
			self.alpha = 0
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
