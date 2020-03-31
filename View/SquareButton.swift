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
		
		var size: CGSize
		if let name = imageName {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
			setImage(UIImage(systemName: name), for: .normal)
			adjustsImageWhenHighlighted = false
			imageView?.clipsToBounds = false
			imageView?.contentMode = .center
			tintColor = Colors.backIcon
			size = CGSize(width: 48, height: 48)
		} else {
			size = CGSize(width: 62.5, height: 60)
			layer.cornerRadius = 22.5
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
