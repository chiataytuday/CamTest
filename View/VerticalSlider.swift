//
//  VerticalSlider.swift
//  Flaneur
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class VerticalSlider : UIView {
	
	enum AlignmentSide {
		case left
		case right
	}
	
	private var min, max: CGFloat
	private(set) var value: CGFloat
	private var translationX: CGFloat!
	private var filledView: UIView!
	
	private var touchOffset: CGFloat?
	private var imageView: UIImageView?
	var delegate: (() -> ())?
	var popup: Popup?
	
	
	init(_ size: CGSize) {
		min = 0; max = 1; value = max
		super.init(frame: CGRect(origin: .zero, size: size))
		roundCorners(corners: .allCorners, radius: frame.width/2)
		backgroundColor = .black
		
		filledView = UIView(frame: bounds)
		filledView.backgroundColor = .white
		addSubview(filledView)
	}
	
	func align(to side: AlignmentSide) {
		guard let superview = superview else { return }
		center.y = superview.frame.midY
		if side == .left {
			center.x = 0
			translationX = -frame.width/2
		} else {
			center.x = superview.frame.maxX
			translationX = frame.width/2
		}
		transform = CGAffineTransform(translationX: translationX, y: 0)
	}
	
	func setImage(_ systemName: String) {
		let image = UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .light))
		imageView = UIImageView(image: image)
		imageView?.tintColor = Colors.gray3
		
		imageView?.center = CGPoint(x: filledView.frame.midX, y: filledView.frame.maxY - imageView!.frame.height/2 - 8)
		insertSubview(imageView!, aboveSubview: filledView)
	}
	
	func range(min: CGFloat, max: CGFloat, value: CGFloat) {
		self.min = min
		self.max = max
		let height = (value-min)/(max-min)*frame.height
		filledView.frame.size.height = height
		filledView.frame.origin.y = frame.height - filledView.frame.height
		self.value = value
	}
	
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchPoint = touches.first!.location(in: self)
		touchOffset = filledView.frame.height + touchPoint.y
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .allowUserInteraction, animations: { [weak self] in
			self?.transform = .identity
		})
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		popup?.setImage(imageView!.image!)
		let rounded = floor(value*10)/10
		popup?.setValue(rounded)
		popup?.show()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchY = touches.first!.location(in: self).y
		var height = touchY - touchOffset!
		if height >= 0 {
			height = 0
		} else if height <= -frame.height {
			height = -frame.height
		}
		
		let ratio = filledView.frame.size.height/frame.size.height
		UIViewPropertyAnimator(duration: 0.08, curve: .linear) { [weak self] in
			self?.filledView.frame = CGRect(origin: CGPoint(x: 0, y: self!.frame.height), size: CGSize(width: self!.frame.width, height: height))
		}.startAnimation()
		
		value = ratio*(max-min)+min
		let rounded = floor(value*10)/10
		popup?.setValue(rounded)
		delegate?()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: { [weak self] in
			self?.transform = CGAffineTransform(translationX: self!.translationX, y: 0)
		})
		popup?.hide()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
