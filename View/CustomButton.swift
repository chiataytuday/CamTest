//
//  SquareButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class CustomButton : UIButton {
	
	var isActive: Bool
	
	enum Size {
		case small, big
	}
	
	init(_ size: Size, _ symbolName: String? = nil, _ isActive: Bool = false) {
		self.isActive = isActive
		super.init(frame: .zero)
		setState(isActive)
		translatesAutoresizingMaskIntoConstraints = false
		if let name = symbolName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: name), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
		}
		
		let rect = size == .small ? CGSize(width: 48, height: 47) :
			CGSize(width: 65, height: 63)
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: rect.width),
			heightAnchor.constraint(equalToConstant: rect.height)
		])
	}
	
	private func setState(_ active: Bool) {
		isActive = active
		
		if active == true {
			tintColor = .systemGray
			backgroundColor = .systemGray5
		} else {
			tintColor = .systemGray3
			backgroundColor = .systemGray6
		}
	}
	
	@objc func touchDown() {
		// shouldn't apply this in init
		imageView?.contentMode = .center
		// because buttons' images of launchscreen will look different
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)

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
