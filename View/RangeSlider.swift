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
	
	var isPresented = false
	var looper: AVPlayerLooper?
	var videoPlayer: AVQueuePlayer? {
		willSet {
			beginPoint.time = .zero
			endPoint.time = CMTimeMakeWithSeconds(newValue!.currentItem!.duration.seconds, preferredTimescale: newValue!.currentItem!.asset.duration.timescale)
		}
	}
	
	private var touchOffset: CGFloat?
	private(set) var beginPoint, endPoint: RangePoint!
	private var activeRangePoint, unactiveRangePoint: RangePoint?
	private var pointWidth: CGFloat!
	private var minDistance: CGFloat!
	private var path, range: UIView!
	
	private var midOfRange: CGFloat {
		return (beginPoint.center.x + endPoint.center.x)/2
	}
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		center = frame.origin
		backgroundColor = .systemBackground
		layer.cornerRadius = frame.height/2
		setupSubviews()
	}
	
	private func setupSubviews() {
		path = UIView()
		path.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.38)
		path.frame.size = CGSize(width: frame.width - frame.height, height: 2)
		path.center = CGPoint(x: frame.width/2, y: frame.height/2)
		path.layer.cornerRadius = path.frame.height/2
		addSubview(path)
		
		minDistance = path.frame.width/8
		
		pointWidth = 10
		beginPoint = RangePoint(pointWidth)
		beginPoint.center.y = path.frame.height/2
		beginPoint.minX = pointWidth/2
		beginPoint.setMax = { [weak self] in
			self?.beginPoint.maxX = self!.endPoint.center.x - self!.minDistance
		}
		beginPoint.applyToPlayer = { [weak self] in
			var sec = Double((self!.beginPoint.center.x - self!.pointWidth/2)/self!.path.frame.width)
			sec *= self!.videoPlayer!.currentItem!.duration.seconds
			self?.beginPoint.time = CMTimeMakeWithSeconds(sec, preferredTimescale: self!.videoPlayer!.currentItem!.asset.duration.timescale)
			self?.videoPlayer?.seek(to: self!.beginPoint.time, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(beginPoint)
		
		endPoint = RangePoint(pointWidth)
		endPoint.center.x = path.frame.width - endPoint.frame.width/2
		endPoint.center.y = path.frame.height/2
		endPoint.maxX = path.frame.width - pointWidth/2
		endPoint.setMin = { [weak self] in
			self?.endPoint.minX = self!.beginPoint.center.x + self!.minDistance
		}
		endPoint.applyToPlayer = { [weak self] in
			var sec = Double((self!.endPoint.center.x + self!.pointWidth/2)/self!.path.frame.width)
			sec *= self!.videoPlayer!.currentItem!.duration.seconds
			self?.endPoint.time = CMTimeMakeWithSeconds(sec, preferredTimescale: self!.videoPlayer!.currentItem!.asset.duration.timescale)
			self?.videoPlayer?.seek(to: self!.endPoint.time, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(endPoint)
		
		range = UIView(frame: CGRect(origin: CGPoint(x: self.beginPoint.center.x, y: 0), size: CGSize(width: self.endPoint.center.x - self.beginPoint.center.x, height: self.path.frame.height)))
		range.backgroundColor = .systemGray2
		path.addSubview(range)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: self).x
		if touchX < midOfRange {
			activeRangePoint = beginPoint
			unactiveRangePoint = endPoint
		} else {
			activeRangePoint = endPoint
			unactiveRangePoint = beginPoint
		}
		touchOffset = touchX - activeRangePoint!.center.x
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		videoPlayer?.pause()
		
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
			self.activeRangePoint?.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
		})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: self).x
		let x = touchX - touchOffset!
		setPointPosition(x)
		activeRangePoint?.applyToPlayer()
	}
	
	private func setPointPosition(_ x: CGFloat) {
		activeRangePoint?.setMin?()
		activeRangePoint?.setMax?()
		
		var pos = x
		if x <= activeRangePoint!.minX {
			pos = activeRangePoint!.minX
		} else if x >= activeRangePoint!.maxX {
			pos = activeRangePoint!.maxX
		}
		
		UIViewPropertyAnimator(duration: 0.04, curve: .easeOut) {
			self.activeRangePoint?.center.x = pos
			self.range.frame = CGRect(origin: CGPoint(x: self.beginPoint.center.x, y: 0), size: CGSize(width: self.endPoint.center.x - self.beginPoint.center.x, height: self.path.frame.height))
		}.startAnimation()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.activeRangePoint?.transform = .identity
		})
		
		self.videoPlayer?.currentItem?.forwardPlaybackEndTime = endPoint.time
		videoPlayer?.play()
		touchOffset = nil
		activeRangePoint = nil
		unactiveRangePoint = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
