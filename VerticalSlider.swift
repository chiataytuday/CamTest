//
//  VerticalSlider.swift
//  CamTest
//
//  Created by debavlad on 10.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class VerticalProgressBar: UIView {
	var delegate: (() -> ())!
	private var line, indicator: UIView!
	var value: CGFloat = 0.5
	var offset: CGFloat = 0
	var margin: CGFloat = 20
	
	let numLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
		label.textColor = .white
		return label
	}()
	
	var range: (CGFloat) -> CGFloat
	
	init(frame: CGRect, _ labelOnRight: Bool, _ topName: String?, _ btmName: String?) {
		if labelOnRight {
			margin = 20
			range = { (x) -> CGFloat in return -6 * x + 3 }
		} else {
			margin = -20
			range = { (x) -> CGFloat in return 1 - x }
		}
		super.init(frame: frame)
		
		setupSubviews(labelOnRight)
		setImages(btmName, topName)
	}
	
	private func setImages(_ btmName: String?, _ topName: String?) {
		if let _ = btmName {
			let btmImage = UIImageView(image: UIImage(systemName: btmName!, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
			btmImage.center = CGPoint(x: indicator.center.x, y: line.frame.maxY + 25)
			btmImage.tintColor = .white
			line.addSubview(btmImage)
		}
		
		if let _ = topName {
			let topImage = UIImageView(image: UIImage(systemName: topName!, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
			topImage.center = CGPoint(x: indicator.center.x, y: line.frame.minY - 25)
			topImage.tintColor = .white
			line.addSubview(topImage)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func setupSubviews(_ right: Bool) {
		line = UIView()
		line.frame.size = CGSize(width: 2, height: frame.height)
		line.frame.origin = CGPoint(x: right ? frame.width/5 : frame.width * 4/5 - line.frame.width,
																y: frame.height/2 - line.frame.height/2)
		line.layer.cornerRadius = line.frame.width/2
		line.backgroundColor = .white
		line.addShadow(1.5, 0.3)
		addSubview(line)
		
		indicator = UIView()
		indicator.frame.size = CGSize(width: 16, height: 16)
		indicator.frame.origin = CGPoint(x: line.frame.width/2 - indicator.frame.width/2,
																		 y: line.frame.height/2 - indicator.frame.height/2)
		indicator.layer.cornerRadius = indicator.frame.width/2
		indicator.backgroundColor = .white
		line.addSubview(indicator)
		
		indicator.addSubview(numLabel)
		numLabel.frame.size = CGSize(width: 30, height: 20)
		numLabel.frame.origin.y = -0.75
		numLabel.textAlignment = right ? .left : .right
		numLabel.frame.origin.x = right ? indicator.frame.width + 7.5 : -indicator.frame.width - numLabel.frame.width/2 - 7.5
		
		self.frame.origin = CGPoint(x: right ? 30 : frame.origin.x - self.frame.width - 30,
																y: frame.origin.y - self.frame.height/2)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let y = touches.first?.location(in: self).y else { return }
		offset = indicator.center.y - y

		UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.frame.origin.x += self.margin
			self.alpha = 1
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let t = touches.first?.location(in: self) else { return }
		let y = t.y + offset

		if y >= frame.height {
			indicator.center.y = frame.height
		} else if y <= 0 {
			indicator.center.y = 0
		} else {
			indicator.center.y = y
		}
		
		valueChanged()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.frame.origin.x -= self.margin
			self.alpha = 0
		}, completion: nil)
	}
	
	private func valueChanged() {
		let pos = indicator.frame.origin.y + indicator.frame.height/2
		value = range(pos/frame.height)
		numLabel.text = "\(round((value)*10)/10)"
		delegate()
	}
}

