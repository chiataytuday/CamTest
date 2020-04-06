//
//  GroupView.swift
//  Flaneur
//
//  Created by debavlad on 06.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class GroupView : UIStackView {
	
	init(buttons: [SquareButton]) {
		super.init(frame: .zero)
		buttons.forEach { addArrangedSubview($0) }
		translatesAutoresizingMaskIntoConstraints = false
		distribution = .fillProportionally
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18)
		arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18)
	}
	
	func show() {
		UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: { [weak self] in
			self?.transform = .identity
			self?.alpha = 1
		})
	}
	
	func hide() {
		UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: { [weak self] in
			self?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
			self?.alpha = 0
		})
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
