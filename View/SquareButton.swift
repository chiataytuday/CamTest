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
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
