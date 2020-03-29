//
//  RangeSlider.swift
//  Flaneur
//
//  Created by debavlad on 29.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class RangePoint : UIView {
	
	var update: (() -> ())?
	var setMin, setMax: (() -> ())?
	var minX, maxX: CGFloat!
	
	init(_ diameter: CGFloat, _ pathFrame: CGRect) {
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
		backgroundColor = .white
		layer.cornerRadius = diameter/2
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class RangeSlider : UIView {
	
	var videoPlayer: AVQueuePlayer?
	
	private var touchOffset: CGFloat?
	private var begin, end: RangePoint!
	private var activeRangePoint, unactiveRangePoint: RangePoint?
	private var minDistance: CGFloat!
	private var path, range: UIView!
	
	private var midOfRange: CGFloat {
		return (begin.center.x + end.center.x)/2
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		center = frame.origin
		backgroundColor = .black
		layer.cornerRadius = frame.height/2
		setupSubviews()
	}
	
	private func setupSubviews() {
		path = UIView()
		path.backgroundColor = .systemGray3
		path.frame.size = CGSize(width: frame.width - frame.height, height: 2)
		path.center = CGPoint(x: frame.width/2, y: frame.height/2)
		path.layer.cornerRadius = path.frame.height/2
		path.clipsToBounds = true
		addSubview(path)
		
		minDistance = path.frame.width/8
		
		range = UIView(frame: path.frame)
		range.backgroundColor = .white
		path.addSubview(range)
		
		begin = RangePoint(path.frame.height, path.frame)
		begin.minX = path.frame.height/2
		begin.setMax = {
			self.begin.maxX = self.end.center.x - self.minDistance
		}
		begin.update = {
//			let value = Double((self.begin.center.x - self.begin.frame.width/2)/self.path.frame.width)
//			value *= duration
//			let timescale = videoPlayer?.currentItem?.asset.duration.timescale
//			videoPlayer?.seek(to: CMTimeMakeWithSeconds(value, prefferedTimescale: timescale), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { (_) in })
		}
		path.addSubview(begin)
		
		end = RangePoint(path.frame.height, path.frame)
		end.center.x = path.frame.width - end.frame.width/2
		end.maxX = path.frame.width - end.frame.width/2
		end.setMin = {
			self.end.minX = self.begin.center.x + self.minDistance
		}
		end.update = {
			print("end point moved")
		}
		path.addSubview(end)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let t = touches.first!.location(in: self)
		if t.x < midOfRange {
			activeRangePoint = begin
			unactiveRangePoint = end
		} else {
			activeRangePoint = end
			unactiveRangePoint = begin
		}
		touchOffset = t.x - activeRangePoint!.center.x
		
		UIViewPropertyAnimator(duration: 0.16, curve: .easeOut) {
			self.unactiveRangePoint?.backgroundColor = .systemGray
			self.range.backgroundColor = .systemGray
		}.startAnimation()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let t = touches.first!.location(in: self)
		let x = t.x - touchOffset!
		resizeRangeView(x)
//		activeRangePoint?.update!()
	}
	
	private func resizeRangeView(_ x: CGFloat) {
		// Only one of these methods gets called (one of them is nil)
		activeRangePoint?.setMin?() // So it's ok
		activeRangePoint?.setMax?()
		
		var val = x
		if x <= activeRangePoint!.minX {
			val = activeRangePoint!.minX
		} else if x >= activeRangePoint!.maxX {
			val = activeRangePoint!.maxX
		}
		
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.activeRangePoint!.center.x = val
			self.range.frame = CGRect(origin: CGPoint(x: self.begin.center.x, y: 0), size: CGSize(width: self.end.center.x - self.begin.center.x, height: self.path.frame.height))
		}.startAnimation()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.unactiveRangePoint?.backgroundColor = .white
			self.range.backgroundColor = .white
		}.startAnimation()
		
		touchOffset = nil
		activeRangePoint = nil
		unactiveRangePoint = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

//class RangeSlider : UIView {
//
//	var duration: Double!
//	var player: AVQueuePlayer?
//
//	private var active, unactive: UIView?
//	private var path, begin, end, range: UIView!
//	private var minDistance: CGFloat!
//	private var offset: CGFloat?
//
//	private var midOfRange: CGFloat {
//		return (begin.center.x + end.center.x)/2
//	}
//
//	var startTime: Double {
//		let coef = Double((begin.center.x - begin.frame.width/2)/path.frame.width)
//		return coef * duration
//	}
//
//	var endTime: Double {
//		let coef = Double((end.center.x + end.frame.width/2)/path.frame.width)
//		return coef * duration
//	}
//
//	func setTime(_ seconds: Double) {
//		let timescale = player?.currentItem?.asset.duration.timescale
//		player?.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: timescale!), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { (_) in
//		})
//	}
//
//
//	override init(frame: CGRect) {
//		super.init(frame: frame)
//		center = frame.origin
//		backgroundColor = .black
//		layer.cornerRadius = frame.height/2
//		setupSubviews()
//	}
//
//	private func setupSubviews() {
//		path = UIView()
//		path.backgroundColor = .systemGray3
//		path.frame.size = CGSize(width: frame.width - frame.height, height: 2)
//		path.layer.cornerRadius = path.frame.height/2
//		path.clipsToBounds = true
//
//		range = UIView(frame: path.frame)
//		range.backgroundColor = .white
//
//		begin = UIView()
//		begin.backgroundColor = .white
//		begin.frame.size = CGSize(width: path.frame.height, height: path.frame.height)
//		begin.layer.cornerRadius = begin.frame.height/2
//
//		end = UIView()
//		end.backgroundColor = .white
//		end.frame.size = CGSize(width: path.frame.height, height: path.frame.height)
//		end.center.x = path.frame.width - end.frame.width/2
//		end.layer.cornerRadius = end.frame.height/2
//
//		addSubview(path)
//		path.addSubview(range)
//		path.addSubview(begin)
//		path.addSubview(end)
//
//		path.center = CGPoint(x: frame.width/2, y: frame.height/2)
//		minDistance = path.frame.width/8
//	}
//
//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		let t = touches.first!.location(in: self)
//		if t.x < midOfRange {
//			active = begin
//			unactive = end
//		} else {
//			active = end
//			unactive = begin
//		}
//		offset = t.x - active!.center.x
//
//		UIViewPropertyAnimator(duration: 0.18, curve: .easeOut) {
//			self.unactive!.backgroundColor = .systemGray
//			self.range.backgroundColor = .systemGray
//		}.startAnimation()
//	}
//
//	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//		let t = touches.first!.location(in: self)
//		let x = t.x - offset!
//		resizeRange(x)
//
//		let timescale = player?.currentItem?.asset.duration.timescale
//		player?.seek(to: CMTimeMakeWithSeconds(endTime, preferredTimescale: timescale!), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { (_) in
//		})
//	}
//
//	func setTime(_ activePoint: UIView) {
//		var time: Double
//		switch activePoint == begin {
//			case true:
//				time = Double((begin.center.x - begin.frame.width/2)/path.frame.width) * duration
//			case false:
//				time = Double((end.center.x + end.frame.width/2)/path.frame.width) * duration
//		}
//		setTime(time)
//	}
//
//	private func resizeRange(_ x: CGFloat) {
//		// slider is left and ok / not ok
//		// slider is mid and ok
//		// slider is right and ok / not ok
//
////		var val: CGFloat
////		if active == begin && x - active!.frame.width/2 <= 0 {
////			val = active!.frame.width/2
////		} else if active == end && x >= path.frame.width - active!.frame.width/2 {
////			val = path.frame.width - active!.frame.width/2
////		} else if abs(x - unactive!.center.x) >= minDistance {
////			if active == begin && x > end.center.x || active == end && x < begin.center.x {
////				return
////			}
////			val = x
////		} else {
////			val = unactive!.center.x + (active == begin ? -minDistance : minDistance)
////		}
////
////		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
////			self.active!.center.x = val
////			self.range.frame = CGRect(origin: CGPoint(x: self.begin.center.x, y: 0), size: CGSize(width: self.end.center.x - self.begin.center.x, height: self.path.frame.height))
////		}.startAnimation()
//	}
//
//	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
//			self.unactive!.backgroundColor = .white
//			self.range.backgroundColor = .white
//		}.startAnimation()
//
//		offset = nil
//		active = nil
//		unactive = nil
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}
