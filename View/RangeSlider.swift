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
	
	var looper: AVPlayerLooper?
	var videoPlayer: AVQueuePlayer? {
		willSet {
			begin.time = .zero
			end.time = CMTimeMakeWithSeconds(newValue!.currentItem!.duration.seconds, preferredTimescale: newValue!.currentItem!.asset.duration.timescale)
		}
	}
	
	var isPresented = false
	
	private var touchOffset: CGFloat?
	private(set) var begin, end: RangePoint!
	private var activeRangePoint, unactiveRangePoint: RangePoint?
	private var pointWidth: CGFloat!
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
		path.backgroundColor = .systemGray4
		path.frame.size = CGSize(width: frame.width - frame.height, height: 4)
		path.center = CGPoint(x: frame.width/2, y: frame.height/2)
		path.layer.cornerRadius = path.frame.height/2
		addSubview(path)
		
		minDistance = path.frame.width/8
		
		range = UIView(frame: CGRect(origin: .zero, size: path.frame.size))
		range.backgroundColor = .systemGray2
		path.addSubview(range)
		
		pointWidth = path.frame.height * 1.75
		begin = RangePoint(pointWidth, path.frame)
		begin.center.y = path.frame.height/2
		begin.minX = pointWidth/2
		begin.setMax = {
			self.begin.maxX = self.end.center.x - self.minDistance
		}
		begin.update = {
			var sec = Double((self.begin.center.x - self.pointWidth/2)/self.path.frame.width)
			sec *= self.videoPlayer!.currentItem!.duration.seconds
			self.begin.time = CMTimeMakeWithSeconds(sec, preferredTimescale: self.videoPlayer!.currentItem!.asset.duration.timescale)
			self.videoPlayer?.seek(to: self.begin.time!, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(begin)
		
		end = RangePoint(pointWidth, path.frame)
		end.center.x = path.frame.width - end.frame.width/2
		end.center.y = path.frame.height/2
		end.maxX = path.frame.width - pointWidth/2
		end.setMin = {
			self.end.minX = self.begin.center.x + self.minDistance
		}
		end.update = {
			var sec = Double((self.end.center.x + self.pointWidth/2)/self.path.frame.width)
			sec *= self.videoPlayer!.currentItem!.duration.seconds
			self.end.time = CMTimeMakeWithSeconds(sec, preferredTimescale: self.videoPlayer!.currentItem!.asset.duration.timescale)
			self.videoPlayer?.seek(to: self.end.time!, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(end)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
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
		
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
			self.activeRangePoint?.transform = CGAffineTransform(scaleX: 1.75, y: 1.75)
		})
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
		
		UIViewPropertyAnimator(duration: 0.075, curve: .easeOut) {
			self.activeRangePoint!.center.x = val
			self.range.frame = CGRect(origin: CGPoint(x: self.begin.center.x, y: 0), size: CGSize(width: self.end.center.x - self.begin.center.x, height: self.path.frame.height))
		}.startAnimation()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.activeRangePoint?.transform = CGAffineTransform.identity
		})
		
		self.videoPlayer?.currentItem?.forwardPlaybackEndTime = end.time!
		videoPlayer?.play()
		touchOffset = nil
		activeRangePoint = nil
		unactiveRangePoint = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
