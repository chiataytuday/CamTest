//
//  VerticalSlider.swift
//  CamTest
//
//  Created by debavlad on 10.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class VerticalProgressBar: UIView {
	var valueChanged: (() -> ())!
	private var line, indicator: UIView!
	var indicatorValue: CGFloat = 0.5
	var lineMargin: CGFloat = 20
	var touchOffset: CGFloat = 0
	
	let numLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
		label.textColor = .white
		return label
	}()
	
	var range: (CGFloat) -> CGFloat
	
	init(frame: CGRect, _ labelOnRight: Bool, _ topName: String?, _ btmName: String?) {
		if labelOnRight {
			lineMargin = 20
			range = { (x) -> CGFloat in return -6 * x + 3 }
		} else {
			lineMargin = -20
			range = { (x) -> CGFloat in return 1 - x }
		}
		super.init(frame: frame)
		
		setupSubviews(labelOnRight)
		setImages(btmName, topName)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let y = touches.first?.location(in: self).y else { return }
		touchOffset = indicator.center.y - y

		UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.frame.origin.x += self.lineMargin
			self.alpha = 1
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let t = touches.first?.location(in: self) else { return }
		let y = t.y + touchOffset

		if y >= frame.height {
			indicator.center.y = frame.height
		} else if y <= 0 {
			indicator.center.y = 0
		} else {
			indicator.center.y = y
		}
		
		updateSubviews()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.frame.origin.x -= self.lineMargin
			self.alpha = 0
		}, completion: nil)
	}
}

extension VerticalProgressBar {
	private func updateSubviews() {
		let y = indicator.frame.origin.y + indicator.frame.height/2
		indicatorValue = range(y/frame.height)
		numLabel.text = "\(round((indicatorValue)*10)/10)"
		valueChanged()
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
	
	private func setupSubviews(_ labelOnRight: Bool) {
		line = UIView()
		line.frame.size = CGSize(width: 2, height: frame.height)
		line.frame.origin = CGPoint(x: labelOnRight ? frame.width/5 : frame.width * 4/5 - line.frame.width,
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
		numLabel.textAlignment = labelOnRight ? .left : .right
		numLabel.frame.origin.x = labelOnRight ? indicator.frame.width + 7.5 : -indicator.frame.width - numLabel.frame.width/2 - 7.5
		
		self.frame.origin = CGPoint(x: labelOnRight ? 30 : frame.origin.x - self.frame.width - 30,
																y: frame.origin.y - self.frame.height/2)
	}
}
