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
	static let buttonLabel = rgb(140, 140, 140)
	static let backIcon = rgb(72, 72, 72)
	static let permissionIcon = rgb(100, 100, 100)
//	static let red = rgb(253, 70, 56)
//	static let yellow = rgb(254, 199, 32)
	static let permissionBorder = rgb(45, 45, 45)
	static let permissionBackground = rgb(12, 12, 12)
	
	static let gray1 = gray(38)
	static let gray2 = gray(67)
	static let gray3 = gray(85)
	static let gray4 = gray(123)
	static let gray5 = gray(157)
	static let gray6 = gray(196)
	static let gray7 = gray(217)
	static let gray8 = gray(233)
	static let gray9 = gray(245)
	static let red = rgb(244, 68, 54)
	static let yellow = rgb(253, 216, 54)
	
	private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
		return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
	}
	
	private static func gray(_ white: CGFloat) -> UIColor {
		return UIColor(red: white/255, green: white/255, blue: white/255, alpha: 1)
	}
}
