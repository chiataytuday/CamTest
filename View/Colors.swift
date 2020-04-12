//
//  Colors.swift
//  Flaneur
//
//  Created by debavlad on 12.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Colors {
	
	static let yellow = color(r: 253, g: 209, b: 14)
	
	private static func color(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
		return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
	}
}
