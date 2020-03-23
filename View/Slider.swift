//
//  Slider.swift
//  CamTest
//
//  Created by debavlad on 17.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class Slider: UIView {
	
	enum SliderPosition {
		case left
		case right
	}
	
	private var progressView: UIView!
	private var offset: CGFloat?
	var min, max, value: CGFloat
	let sliderPosition: SliderPosition
	
	private var imageView: UIImageView?
	var popup: Popup?
	var delegate: (() -> ())?
	
	
	init(_ size: CGSize, _ parentFrame: CGRect, _ sliderPosition: SliderPosition) {
		min = 0; max = 1; value = max
		self.sliderPosition = sliderPosition
		super.init(frame: CGRect(origin: .zero, size: size))
		layer.cornerRadius = frame.width/2
		clipsToBounds = true
		backgroundColor = .black
		center = CGPoint(x: sliderPosition == .left ? -frame.width/2 : parentFrame.maxX + frame.width/2, y: parentFrame.midY)
		
		progressView = UIView(frame: bounds)
		progressView.backgroundColor = .systemGray6
		addSubview(progressView)
	}
	
	func setImage(_ imageName: String) {
		let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .light))
		imageView = UIImageView(image: image)
		imageView?.tintColor = .systemGray2
		
		imageView?.center = CGPoint(x: progressView.frame.midX,
																y: progressView.frame.maxY - imageView!.frame.height/2 - 8)
		insertSubview(imageView!, aboveSubview: progressView)
	}
	
	func customRange(_ min: CGFloat, _ max: CGFloat, _ value: CGFloat) {
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
		let x: CGFloat = sliderPosition == .left ? frame.width/2: -frame.width/2
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
			self.transform = CGAffineTransform(translationX: x, y: 0)
			self.progressView.backgroundColor = .systemGray6
		}, completion: nil)
		popup?.setImage(imageView!.image!)
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
		progressView.frame = CGRect(origin: CGPoint(x: 0, y: frame.height), size: CGSize(width: frame.width, height: height))
		
		value = ratio*(max-min)+min
		let rounded = floor(value*10)/10
		popup?.update(rounded)
		delegate?()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseIn, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform.identity
			self.progressView.backgroundColor = .systemGray6
		})
		popup?.hide()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

