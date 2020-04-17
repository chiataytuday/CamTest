//
//  RangePoint.swift
//  Flaneur
//
//  Created by debavlad on 30.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

final class RangePoint: UIView {
	
	var minX, maxX: CGFloat!
	var setMinX, setMaxX: (() -> ())?
	var applyToPlayer: (() -> ())!
	var time: CMTime!
	
	init(diameter: CGFloat) {
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
		backgroundColor = .systemGray2
		layer.cornerRadius = diameter/2
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
