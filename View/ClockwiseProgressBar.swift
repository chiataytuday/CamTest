//
//  ClockwiseProgressBar.swift
//  Flaneur
//
//  Created by debavlad on 05.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

final class ClockwiseProgressBar : UIView {
	
	private let filledShapeLayer: CAShapeLayer = {
		let shapeLayer = CAShapeLayer()
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.strokeColor = UIColor.white.cgColor
		shapeLayer.strokeEnd = 0
		return shapeLayer
	}()
	
	init(diameter: CGFloat) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: diameter),
			heightAnchor.constraint(equalToConstant: diameter)
		])
		backgroundColor = .black
		layer.cornerRadius = diameter/2
		clipsToBounds = true
		
		let circularPath = UIBezierPath(arcCenter: CGPoint(x: diameter/2, y: diameter/2), radius: diameter/4 + 1, startAngle: -.pi/2, endAngle: .pi*3/2, clockwise: true)
		filledShapeLayer.path = circularPath.cgPath
		filledShapeLayer.lineWidth = diameter/2 + 2
		layer.addSublayer(filledShapeLayer)
	}
	
	func start(duration: TimeInterval) {
		let opacityAnim = CABasicAnimation(keyPath: "opacity")
		opacityAnim.fromValue = 0
		opacityAnim.toValue = 1
		opacityAnim.duration = 0.075
		opacityAnim.fillMode = .forwards
		opacityAnim.isRemovedOnCompletion = false
		filledShapeLayer.add(opacityAnim, forKey: "opacityAnim")
		
		let strokeAnim = CABasicAnimation(keyPath: "strokeEnd")
		strokeAnim.fromValue = 0
		strokeAnim.toValue = 1
		strokeAnim.duration = duration
		strokeAnim.fillMode = .forwards
		strokeAnim.isRemovedOnCompletion = false
		filledShapeLayer.add(strokeAnim, forKey: "strokeAnim")
	}
	
	func finish() {
		let strokeEnd = filledShapeLayer.presentation()!.strokeEnd
		filledShapeLayer.strokeEnd = strokeEnd
		filledShapeLayer.removeAllAnimations()
		
		let opacityAnim = CABasicAnimation(keyPath: "opacity")
		opacityAnim.fromValue = 1
		opacityAnim.toValue = 0
		opacityAnim.duration = 0.085
		opacityAnim.fillMode = .forwards
		opacityAnim.isRemovedOnCompletion = false
		filledShapeLayer.add(opacityAnim, forKey: "opacityAnim")
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
