//
//  Colors.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Colors {
	static let gray1 = gray(38)
	static let gray2 = gray(67)
	static let gray3 = gray(85)
	static let gray4 = gray(123)
	static let gray5 = gray(157)
	static let gray6 = gray(196)
	static let gray7 = gray(217)
	static let gray8 = gray(233)
	static let gray9 = gray(245)
	static let red = rgb(r: 244, g: 68, b: 54)
	static let yellow = rgb(r: 253, g: 216, b: 54)
	
	private static func rgb(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
		return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
	}
	
	private static func gray(_ c: CGFloat) -> UIColor {
		return UIColor(red: c/255, green: c/255, blue: c/255, alpha: 1)
	}
}
