//
//  RangePoint.swift
//  Flaneur
//
//  Created by debavlad on 30.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class RangePoint : UIView {
	
	var applyToPlayer: (() -> ())!
	var setMin, setMax: (() -> ())?
	var minX, maxX: CGFloat!
	var time: CMTime!
	
	init(_ diameter: CGFloat) {
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
		backgroundColor = Colors.gray5
		layer.cornerRadius = diameter/2
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
