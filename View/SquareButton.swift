//
//  SquareButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class SquareButton : UIButton {
	
	init(size: CGSize, _ systemImageName: String? = nil) {
		super.init(frame: .zero)
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false
		if let systemName = systemImageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: systemName), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
			tintColor = Colors.gray3
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
		
		if tag == 0 {
			tintColor = Colors.gray5
			backgroundColor = Colors.gray1
			tag = 1
		} else {
			tintColor = Colors.gray3
			backgroundColor = .black
			tag = 0
		}
		
		imageView?.transform = CGAffineTransform(rotationAngle: .pi/2.5)
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [.curveLinear, .allowUserInteraction], animations: {
			self.imageView?.transform = .identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
