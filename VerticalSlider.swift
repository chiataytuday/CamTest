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
	
	let numLabel: UILabel = {
		let label = UILabel()
		label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
		label.textColor = .white
		label.alpha = 0
		return label
	}()
	
	var calc: (CGFloat) -> CGFloat
	
	init(frame: CGRect, _ right: Bool, _ topIcon: String?, _ bottomIcon: String?) {
		if right {
			calc = { (x) -> CGFloat in
				return -6 * x + 3
			}
		} else {
			calc = { (x) -> CGFloat in
				return 1 - x
			}
		}
		
		super.init(frame: frame)
		setupSubviews(right)
		self.frame.origin = CGPoint(x: right ? 30 : frame.origin.x - self.frame.width - 30, y: frame.origin.y - self.frame.height/2)
		
		numLabel.textAlignment = right ? .left : .right
		numLabel.frame.origin.x = right ? indicator.frame.width + 7.5 : -indicator.frame.width - numLabel.frame.width/2 - 7.5
		
		if let bottomName = bottomIcon {
			let bottom = UIImageView(image: UIImage(systemName: bottomName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
			bottom.tintColor = .white
			bottom.frame.origin.y = line.frame.height + bottom.frame.height/2 + 7.5
			bottom.frame.origin.x = -bottom.frame.width/2 + line.frame.width/2
			line.addSubview(bottom)
		}
		if let topName = topIcon {
			let top = UIImageView(image: UIImage(systemName: topName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
			top.tintColor = .white
			top.frame.origin.y = -top.frame.height - top.frame.height/2 - 7.5
			top.frame.origin.x = -top.frame.width/2 + line.frame.width/2
			line.addSubview(top)
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
		addSubview(line)
		
		indicator = UIView()
		indicator.frame.size = CGSize(width: 16, height: 16)
		indicator.frame.origin = CGPoint(x: line.frame.width/2 - indicator.frame.width/2, y: line.frame.height/2 - indicator.frame.height/2)
		indicator.layer.cornerRadius = indicator.frame.width/2
		indicator.backgroundColor = .white
		line.addSubview(indicator)
		
		indicator.addSubview(numLabel)
		numLabel.frame.size = CGSize(width: 30, height: 20)
		numLabel.frame.origin.y = -0.75
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touchY = touches.first?.location(in: self).y else { return }
		offset = indicator.frame.origin.y - touchY + indicator.frame.height/2
		UIViewPropertyAnimator(duration: 0.16, curve: .easeOut) {
			self.numLabel.alpha = 1
		}.startAnimation()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touchY = touches.first?.location(in: self).y else { return }
		let y = touchY + offset - indicator.frame.height/2
		
		if y >= frame.height - indicator.frame.height/2 {
			indicator.frame.origin.y = frame.height - indicator.frame.height/2
		} else if y <= -indicator.frame.height/2 {
			indicator.frame.origin.y = -indicator.frame.height/2
		} else {
			indicator.frame.origin.y = y
		}
		
		valueChanged()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIViewPropertyAnimator(duration: 0.16, curve: .easeOut) {
			self.numLabel.alpha = 0
		}.startAnimation()
	}
	
	private func valueChanged() {
		let pos = indicator.frame.origin.y + indicator.frame.height/2
		value = calc(pos/frame.height)
		numLabel.text = "\(round((value)*10)/10)"
		delegate()
	}
}

