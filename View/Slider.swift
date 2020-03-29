//
//  Slider.swift
//  CamTest
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Slider: UIView {
	
	enum SliderAlignment {
		case left
		case right
	}
	
	private var progressView: UIView!
	private var offset: CGFloat?
	private var min, max: CGFloat
	private(set) var value: CGFloat
	let alignment: SliderAlignment
	
	private var imageView: UIImageView?
	var delegate: (() -> ())?
	var popup: Popup?
	
	
	init(_ size: CGSize, _ superviewFrame: CGRect, _ alignment: SliderAlignment) {
		min = 0; max = 1; value = max
		self.alignment = alignment
		super.init(frame: CGRect(origin: .zero, size: size))
		roundCorners(corners: [.bottomLeft, .bottomRight, .topLeft, .topRight], radius: frame.width/2)
		backgroundColor = .black
		center = CGPoint(x: alignment == .left ? -frame.width/2 : superviewFrame.maxX + frame.width/2, y: superviewFrame.midY)
		
		progressView = UIView(frame: bounds)
		progressView.backgroundColor = .white
		addSubview(progressView)
	}
	
	func setImage(_ imageName: String) {
		let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .light))
		imageView = UIImageView(image: image)
		imageView?.tintColor = Colors.sliderIcon
		
		imageView?.center = CGPoint(x: progressView.frame.midX, y: progressView.frame.maxY - imageView!.frame.height/2 - 8)
		insertSubview(imageView!, aboveSubview: progressView)
	}
	
	func setRange(_ min: CGFloat, _ max: CGFloat, _ value: CGFloat) {
		self.min = min
		self.max = max
		
		let height = (value-min)/(max-min)*frame.height
		progressView.frame.size.height = height
		progressView.frame.origin.y = frame.height - progressView.frame.height
		self.value = value
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: self) else { return }
		offset = progressView.frame.height + touch.y
		let x: CGFloat = alignment == .left ? frame.width/2: -frame.width/2
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.transform = CGAffineTransform(translationX: x, y: 0)
		})
		popup?.setIconImage(imageView!.image!)
		popup?.show()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: self) else { return }
		var height = touch.y - offset!
		if height > 0 {
			height = 0
		} else if height < -frame.height {
			height = -frame.height
		}
		
		let ratio = progressView.frame.size.height/frame.size.height
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.progressView.frame = CGRect(origin: CGPoint(x: 0, y: self.frame.height), size: CGSize(width: self.frame.width, height: height))
		}.startAnimation()
		
		
		value = ratio*(max-min)+min
		let rounded = floor(value*10)/10
		popup?.setLabelDigit(rounded)
		delegate?()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform.identity
		})
		popup?.hide()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

