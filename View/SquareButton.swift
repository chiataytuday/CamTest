//
//  SquareButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class SquareButton : UIButton {
	
	private var isActive: Bool
	
	func setActive(_ active: Bool) {
		if active == true {
			tintColor = Colors.gray5
			backgroundColor = Colors.gray1
		} else {
			tintColor = Colors.gray3
			backgroundColor = .black
		}
	}
	
	init(size: CGSize, _ systemImageName: String? = nil, _ isActive: Bool = false) {
		self.isActive = isActive
		super.init(frame: .zero)
		setActive(isActive)
		translatesAutoresizingMaskIntoConstraints = false
		if let systemName = systemImageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: systemName), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
		}
		
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: size.width),
			heightAnchor.constraint(equalToConstant: size.height)
		])
	}
	
	@objc func touchDown() {
		// shouldn't apply this in init
		imageView?.contentMode = .center
		// because buttons' images of launchscreen will look different
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)

		isActive = !isActive
		setActive(isActive)
		
		imageView?.transform = CGAffineTransform(rotationAngle: .pi/2.5)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [.curveLinear, .allowUserInteraction], animations: {
			self.imageView?.transform = .identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
