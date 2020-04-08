//
//  StatusBar.swift
//  Flaneur
//
//  Created by debavlad on 08.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class StatusBar : UIStackView {
	
	var torchItem, lockItem, exposureItem, lensItem: UIButton!
	
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		heightAnchor.constraint(equalToConstant: 25).isActive = true
		distribution = .equalCentering
		spacing = 6
		setupSubviews()
	}
	
	private func setupSubviews() {
		torchItem = createButton("bolt.fill")
		addArrangedSubview(torchItem)
		lockItem = createButton("lock.fill")
		addArrangedSubview(lockItem)
		exposureItem = createButton("sun.max.fill")
		addArrangedSubview(exposureItem)
		lensItem = createButton("scope")
		addArrangedSubview(lensItem)
	}
	
	private func createButton(_ imageName: String) -> UIButton {
		let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15))
		let btn = UIButton(type: .custom)
		btn.backgroundColor = .systemYellow
		btn.tintColor = .systemBackground
		btn.layer.cornerRadius = 7.5
		btn.isUserInteractionEnabled = false
		btn.setImage(image, for: .normal)
		btn.isHidden = true
		NSLayoutConstraint.activate([
			btn.heightAnchor.constraint(equalToConstant: 25),
			btn.widthAnchor.constraint(equalToConstant: 45)
		])
		return btn
	}
	
	func animate(_ item: UIButton, _ isHidden: Bool) {
		let alpha: CGFloat = isHidden ? 0 : 1
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			item.isHidden = isHidden
			item.alpha = alpha
		})
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension UIView {
	func show() {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = .identity
			self.alpha = 1
		})
	}
	
	func hide() {
		UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
			self.alpha = 0
		})
	}
}
