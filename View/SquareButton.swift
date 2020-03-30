//
//  SquareButton.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class SquareButton : UIButton {
	
	init(_ imageName: String?) {
		super.init(frame: .zero)
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false
		var width: CGFloat
		if let name = imageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: name), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
			imageView?.contentMode = .center
			tintColor = Colors.disabledButton
			width = 52.5
		} else {
			width = 60
		}
		
		layer.cornerRadius = 22.5
		
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: width + 2.5),
			heightAnchor.constraint(equalToConstant: width)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
