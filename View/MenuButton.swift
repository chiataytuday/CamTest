//
//  MenuButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class MenuButton: UIButton {
	
	init(_ imageName: String?) {
		super.init(frame: .zero)
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false
		if let name = imageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: name), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
			imageView?.contentMode = .center
			tintColor = Colors.disabledButton
		}
		
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 57.5),
			heightAnchor.constraint(equalToConstant: 55)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
