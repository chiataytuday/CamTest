//
//  StatusBar.swift
//  Flaneur
//
//  Created by debavlad on 08.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit



//class StatusItem : UIView {
//
//	init(_ color: UIColor) {
//		super.init(frame: .zero)
//		translatesAutoresizingMaskIntoConstraints = false
//		NSLayoutConstraint.activate([
//			widthAnchor.constraint(equalToConstant: 45),
//			heightAnchor.constraint(equalToConstant: 25)
//		])
//		backgroundColor = .systemYellow
//		layer.cornerRadius = 7
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

class StatusBar : UIStackView {
	
	var torchItem, lockItem, exposureItem, lensItem: UIButton!
	
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		heightAnchor.constraint(equalToConstant: 25).isActive = true
		distribution = .equalCentering
		spacing = 6
		
		torchItem = createButton("bolt.fill")
		lockItem = createButton("lock.fill")
		exposureItem = createButton("sun.max.fill")
		lensItem = createButton("scope")
		addArrangedSubviews([torchItem, lockItem, exposureItem, lensItem])
	}
	
	private func createButton(_ imageName: String) -> UIButton {
		let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15))
		let button = UIButton(type: .custom)
		button.backgroundColor = .systemYellow
		button.tintColor = .systemBackground
		button.layer.cornerRadius = 7.5
		button.isUserInteractionEnabled = false
		button.setImage(image, for: .normal)
		button.isHidden = true
		NSLayoutConstraint.activate([
			button.heightAnchor.constraint(equalToConstant: 25),
			button.widthAnchor.constraint(equalToConstant: 45)
		])
		return button
	}
	
	private func addArrangedSubviews(_ views: [UIView]) {
		for subview in views {
			addArrangedSubview(subview)
		}
	}
	
	func animate(_ item: UIButton, _ isHidden: Bool) {
		let alpha: CGFloat = isHidden ? 0 : 1
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [], animations: {
			item.isHidden = isHidden
			item.alpha = alpha
		})
	}
	
	func hide() {
		UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
			self.alpha = 0
		})
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
