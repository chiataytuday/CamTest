//
//  SquareButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class CustomButton : UIButton {
	
	private(set) var isActive: Bool
	
	func setState(_ active: Bool) {
		isActive = active
		
		if active == true {
			tintColor = .systemGray
			backgroundColor = .systemGray5
		} else {
			tintColor = .systemGray3
			backgroundColor = .systemBackground
		}
	}
	
	enum ButtonSize {
		case small, big
	}
	
	init(_ buttonSize: ButtonSize, _ systemImageName: String? = nil, _ isActive: Bool = false) {
		self.isActive = isActive
		super.init(frame: .zero)
		setState(isActive)
		translatesAutoresizingMaskIntoConstraints = false
		if let systemName = systemImageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: systemName), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
		}
		
		let size = buttonSize == .small ? CGSize(width: 46, height: 45) : CGSize(width: 62, height: 60)
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
		setState(isActive)
		
		imageView?.transform = CGAffineTransform(rotationAngle: .pi/2.5)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [.curveLinear, .allowUserInteraction], animations: {
			self.imageView?.transform = .identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
