//
//  Popup.swift
//  CamTest
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Popup: UIView {
		
	var expanded = false
	
	private let imageView: UIImageView = {
		let image = UIImage(systemName: "sun.max.fill")
		let view = UIImageView(image: image)
		view.tintColor = .systemGray
		return view
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

	
	init(_ origin: CGPoint) {
		let rect = CGRect(x: 0, y: 0, width: imageView.frame.width + valueLabel.frame.width + 5, height: imageView.frame.height)
		super.init(frame: rect.insetBy(dx: -16, dy: -7.25))
		
		valueLabel.frame.origin.x += imageView.frame.width + 5
		for el in [imageView, valueLabel] {
			el.frame.origin.x += 16
			el.center.y = center.y + 7.25
		}
		
		center = origin
		backgroundColor = .black
		layer.cornerRadius = 17.5
		addSubview(imageView)
		addSubview(valueLabel)
		alpha = 0
	}
	
	func update(_ value: CGFloat) {
		valueLabel.text = "\(value)"
		valueLabel.sizeToFit()
		
		if value < 0 && !expanded || value >= 0 && expanded {
			let args: (CGFloat, CGFloat) = expanded ? (-10, 5) : (10, -5)
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
				self.frame.size.width += args.0
				self.frame.origin.x += args.1
			}, completion: nil)
			expanded = value < 0
		}
	}
	
	func show() {
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform(translationX: 0, y: 20)
			self.alpha = 1
		}, completion: nil)
	}
	
	func hide() {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.5, options: [.curveLinear, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform.identity
			self.alpha = 0
		}, completion: nil)
	}
	
	func setImage(_ image: UIImage) {
		imageView.image = image
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
