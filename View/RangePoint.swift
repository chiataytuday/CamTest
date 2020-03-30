//
//  RangePoint.swift
//  Flaneur
//
//  Created by debavlad on 30.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class RangePoint : UIView {
	
	var update: (() -> ())?
	var setMin, setMax: (() -> ())?
	var value: Double?
	var minX, maxX: CGFloat!
	
	init(_ diameter: CGFloat, _ pathFrame: CGRect) {
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
		backgroundColor = .white
		layer.cornerRadius = diameter/2
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
