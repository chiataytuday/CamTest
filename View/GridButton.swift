//
//  GridButton.swift
//  Flaneur
//
//  Created by debavlad on 10.05.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class GridButton: UIButton {

	var isActive = false
	let viewToAnimate: UIView

	init(_ gridLinesView: UIView) {
		viewToAnimate = gridLinesView
		super.init(frame: .zero)
		backgroundColor = .systemGray6
		let config = UIImage.SymbolConfiguration(pointSize: 16)
		setImage(UIImage(systemName: "grid", withConfiguration: config), for: .normal)
		tintColor = .systemGray3
		adjustsImageWhenHighlighted = false
		layer.cornerRadius = 12

		translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 41),
			heightAnchor.constraint(equalToConstant: 26)
		])

		addTarget(self, action: #selector(touchDown), for: .touchDown)
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let newArea = CGRect(x: self.bounds.origin.x - 20, y: self.bounds.origin.y - 20, width: self.bounds.size.width + 40, height: self.bounds.size.height + 40)
		return newArea.contains(point)
	}

	@objc func touchDown() {
		isActive = !isActive
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		let a: (UIColor, UIColor) = isActive ? (.systemGray, .systemGray5) : (.systemGray3, .systemGray6)
		let alpha: CGFloat = isActive ? 0.3 : 0
		UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.viewToAnimate.alpha = alpha
			self.tintColor = a.0
			self.backgroundColor = a.1
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
