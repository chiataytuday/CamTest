//
//  Colors.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Colors {
	static let sliderRange = rgb(34, 34, 34)
	static let sliderIcon = rgb(95, 95, 95)
	static let popupContent = rgb(132, 132, 132)
	static let disabledButton = rgb(45, 45, 45)
	static let enabledButton = rgb(142, 142, 142)
	static let buttonDown = rgb(20, 20, 20)
	static let buttonUp = rgb(30, 30, 30)
	static let red = rgb(205, 52, 41)
	static let yellow = rgb(254, 199, 32)
	static let buttonLabel = rgb(140, 140, 140)
	static let backIcon = rgb(72, 72, 72)
	static let permissionIcon = rgb(100, 100, 100)
	static let permissionBorder = rgb(45, 45, 45)
	static let permissionBackground = rgb(12, 12, 12)
	
	private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
		return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
	}
}
