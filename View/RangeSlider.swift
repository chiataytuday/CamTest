//
//  RangeSlider.swift
//  Flaneur
//
//  Created by debavlad on 28.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class RangeSlider : UIView {
	
	private var active, unactive: UIView?
	private var beginPoint, endPoint, range: UIView!
	private var offset: CGFloat?
	var duration: Double!
	var player: AVQueuePlayer?
	
	private var mid: CGFloat {
		return (beginPoint.center.x + endPoint.center.x)/2
	}
	
	private var minDuration: CGFloat {
		return frame.width/6
	}
	
	var startTime: Double {
		let coef = Double(beginPoint.center.x - beginPoint.frame.width/2)/300
		return coef * duration
	}
	
	var endTime: Double {
		let coef = Double(endPoint.center.x + endPoint.frame.width/2)/300
		return coef * duration
	}
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		center = frame.origin
		backgroundColor = .systemGray5
		layer.cornerRadius = frame.height/2
		clipsToBounds = true
		setupPoints()
	}
	
	private func setupPoints() {
		beginPoint = UIView()
		beginPoint.backgroundColor = .white
		beginPoint.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
		beginPoint.frame.size = CGSize(width: frame.height, height: frame.height)
		beginPoint.layer.cornerRadius = beginPoint.frame.height/2
		
		endPoint = UIView()
		endPoint.backgroundColor = .white
		endPoint.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
		endPoint.frame.size = CGSize(width: frame.height, height: frame.height)
		endPoint.layer.cornerRadius = endPoint.frame.height/2
		endPoint.center.x = frame.width - endPoint.frame.width/2
		
		range = UIView(frame: CGRect(origin: beginPoint.center, size: CGSize(width: endPoint.center.x - endPoint.frame.width/2, height: frame.height)))
		range.backgroundColor = .white
		addSubview(range)
		
		addSubview(beginPoint)
		addSubview(endPoint)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first!.location(in: self)
		if touch.x < mid {
			active = beginPoint
			unactive = endPoint
		} else {
			active = endPoint
			unactive = beginPoint
		}
		offset = touch.x - active!.center.x
		
		UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
			self.unactive!.backgroundColor = .systemGray
			self.range.backgroundColor = Colors.buttonLabel
		}.startAnimation()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touch = touches.first!.location(in: self)
		let pos = touch.x - offset!
		resizeRange(pos)
		let timescale = player?.currentItem?.asset.duration.timescale
		player?.seek(to: CMTimeMakeWithSeconds(endTime, preferredTimescale: timescale!), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { (_) in
		})
	}
	
	private func resizeRange(_ x: CGFloat) {
		var tmp: CGFloat
		if active == beginPoint && x - active!.frame.width/2 <= 0 {
			tmp = active!.frame.width/2
		} else if active == endPoint && x >= frame.width - active!.frame.width/2 {
			tmp = frame.width - active!.frame.width/2
		} else if abs(x - unactive!.center.x) >= minDuration {
			if active == beginPoint && x > endPoint.center.x || active == endPoint && x < beginPoint.center.x {
				return
			}
			tmp = x
		} else {
			tmp = unactive!.center.x + (active == beginPoint ? -minDuration : minDuration)
		}
		
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.active!.center.x = tmp
			self.range.frame = CGRect(origin: self.beginPoint.center, size: CGSize(width: self.endPoint.center.x - self.beginPoint.center.x, height: self.frame.height))
		}.startAnimation()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.unactive!.backgroundColor = .white
			self.range.backgroundColor = .white
		}.startAnimation()
		
		offset = nil
		active = nil
		unactive = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
