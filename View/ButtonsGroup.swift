//
//  GroupView.swift
//  Flaneur
//
//  Created by debavlad on 06.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class ButtonsGroup : UIStackView {
	
	init(_ buttons: [CustomButton]) {
		super.init(frame: .zero)
		buttons.forEach { addArrangedSubview($0) }
		translatesAutoresizingMaskIntoConstraints = false
		distribution = .fillProportionally
		spacing = -1
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18)
		arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18)
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
