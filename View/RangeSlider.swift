//
//  RangeSlider.swift
//  Flaneur
//
//  Created by debavlad on 29.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class RangeSlider : UIView {
	
	var videoPlayer: AVQueuePlayer?
	var duration: Double? {
		return videoPlayer?.currentItem?.duration.seconds
	}
	var timescale: CMTimeScale? {
		return videoPlayer?.currentItem?.asset.duration.timescale
	}
	
	var isPresented = false
	
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
		backgroundColor = Colors.buttonUp
		layer.cornerRadius = frame.height/2
		setupSubviews()
	}
	
	private func setupSubviews() {
		path = UIView()
		path.backgroundColor = .systemGray3
		path.frame.size = CGSize(width: frame.width - frame.height, height: 3)
		path.center = CGPoint(x: frame.width/2, y: frame.height/2)
		path.layer.cornerRadius = path.frame.height/2
		path.clipsToBounds = true
		addSubview(path)
		
		minDistance = path.frame.width/8
		
		range = UIView(frame: CGRect(origin: .zero, size: path.frame.size))
		range.backgroundColor = .white
		path.addSubview(range)
		
		begin = RangePoint(path.frame.height, path.frame)
		begin.minX = path.frame.height/2
		begin.setMax = {
			self.begin.maxX = self.end.center.x - self.minDistance
		}
		begin.update = {
			var value = Double((self.begin.center.x - self.begin.frame.width/2)/self.path.frame.width)
			value *= self.duration!
			print("begin \(value)")
			self.videoPlayer?.seek(to: CMTimeMakeWithSeconds(value, preferredTimescale: self.timescale!), toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(begin)
		
		end = RangePoint(path.frame.height, path.frame)
		end.center.x = path.frame.width - end.frame.width/2
		end.maxX = path.frame.width - end.frame.width/2
		end.setMin = {
			self.end.minX = self.begin.center.x + self.minDistance
		}
		end.update = {
			var value = Double((self.end.center.x + self.end.frame.width/2)/self.path.frame.width)
			value *= self.duration!
			print("end \(value)")
			self.videoPlayer?.seek(to: CMTimeMakeWithSeconds(value, preferredTimescale: self.timescale!), toleranceBefore: .zero, toleranceAfter: .zero)
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
		videoPlayer?.pause()
		
		UIViewPropertyAnimator(duration: 0.16, curve: .easeOut) {
			self.unactiveRangePoint?.backgroundColor = .systemGray
			self.range.backgroundColor = .systemGray
		}.startAnimation()
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let t = touches.first!.location(in: self)
		let x = t.x - touchOffset!
		resizeRangeView(x)
		activeRangePoint?.update!()
	}
	
	private func resizeRangeView(_ x: CGFloat) {
		activeRangePoint?.setMin?()
		activeRangePoint?.setMax?()
		
		var val = x
		if x <= activeRangePoint!.minX {
			val = activeRangePoint!.minX
		} else if x >= activeRangePoint!.maxX {
			val = activeRangePoint!.maxX
		}
		
		UIViewPropertyAnimator(duration: 0.08, curve: .linear) {
			self.activeRangePoint!.center.x = val
			self.range.frame = CGRect(origin: CGPoint(x: self.begin.center.x, y: 0), size: CGSize(width: self.end.center.x - self.begin.center.x, height: self.path.frame.height))
		}.startAnimation()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
			self.unactiveRangePoint?.backgroundColor = .white
			self.range.backgroundColor = .white
		}.startAnimation()
		
		videoPlayer?.play()
		touchOffset = nil
		activeRangePoint = nil
		unactiveRangePoint = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
