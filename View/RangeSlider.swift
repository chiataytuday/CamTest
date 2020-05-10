//
//  RangeSlider.swift
//  Flaneur
//
//  Created by debavlad on 29.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

final class RangeSlider: UIView {
	
	var isShown = false
	var startPoint, endPoint: RangePoint!
	var videoPlayer: AVQueuePlayer? {
		willSet(player) {
			startPoint.time = .zero
			let duration = player?.currentItem?.duration.seconds
			let timescale = player?.currentItem?.asset.duration.timescale
			endPoint.time = CMTimeMakeWithSeconds(duration!, preferredTimescale: timescale!)
		}
	}
	
	private var touchOffset: CGFloat?
	private var activePoint, inactivePoint: RangePoint?
	private var initialPointWidth: CGFloat!
	private var minDistance: CGFloat!
	private var path, range: UIView!
	
	private var centerOfRange: CGFloat {
		return (startPoint.center.x + endPoint.center.x)/2
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		center = frame.origin
		backgroundColor = .systemGray6
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
		initialPointWidth = 10
		startPoint = RangePoint(diameter: initialPointWidth)
		startPoint.center.y = path.frame.height/2
		startPoint.minX = initialPointWidth/2
		startPoint.setMaxX = { [weak self] in
			self?.startPoint.maxX = self!.endPoint.center.x - self!.minDistance
		}
		startPoint.applyToPlayer = { [weak self] in
			var coef = Double((self!.startPoint.center.x - self!.initialPointWidth/2)/self!.path.frame.width)
			coef *= self!.videoPlayer!.currentItem!.duration.seconds
			self?.startPoint.time = CMTimeMakeWithSeconds(coef, preferredTimescale: self!.videoPlayer!.currentItem!.asset.duration.timescale)
			self?.videoPlayer?.seek(to: self!.startPoint.time, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(startPoint)
		
		endPoint = RangePoint(diameter: initialPointWidth)
		endPoint.center.x = path.frame.width - endPoint.frame.width/2
		endPoint.center.y = path.frame.height/2
		endPoint.maxX = path.frame.width - initialPointWidth/2
		endPoint.setMinX = { [weak self] in
			self?.endPoint.minX = self!.startPoint.center.x + self!.minDistance
		}
		endPoint.applyToPlayer = { [weak self] in
			var coef = Double((self!.endPoint.center.x + self!.initialPointWidth/2)/self!.path.frame.width)
			coef *= self!.videoPlayer!.currentItem!.duration.seconds
			self?.endPoint.time = CMTimeMakeWithSeconds(coef, preferredTimescale: self!.videoPlayer!.currentItem!.asset.duration.timescale)
			self?.videoPlayer?.seek(to: self!.endPoint.time, toleranceBefore: .zero, toleranceAfter: .zero)
		}
		path.addSubview(endPoint)
		
		range = UIView(frame: CGRect(origin: CGPoint(x: self.startPoint.center.x, y: 0), size: CGSize(width: self.endPoint.center.x - self.startPoint.center.x, height: self.path.frame.height)))
		range.backgroundColor = .systemGray2
		path.addSubview(range)
	}
	
	private func movePoint(to x: CGFloat) {
		activePoint?.setMinX?()
		activePoint?.setMaxX?()
		
		var pos = x
		if x <= activePoint!.minX {
			pos = activePoint!.minX
		} else if x >= activePoint!.maxX {
			pos = activePoint!.maxX
		}
		
		UIViewPropertyAnimator(duration: 0.04, curve: .easeOut) {
			self.activePoint?.center.x = pos
			self.range.frame = CGRect(origin: CGPoint(x: self.startPoint.center.x, y: 0), size: CGSize(width: self.endPoint.center.x - self.startPoint.center.x, height: self.path.frame.height))
		}.startAnimation()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: self).x
		if touchX < centerOfRange {
			activePoint = startPoint
			inactivePoint = endPoint
		} else {
			activePoint = endPoint
			inactivePoint = startPoint
		}
		touchOffset = touchX - activePoint!.center.x
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		videoPlayer?.pause()
		
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
			self.activePoint?.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
		})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchX = touches.first!.location(in: self).x
		let x = touchX - touchOffset!
		movePoint(to: x)
		activePoint?.applyToPlayer()
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
			self.activePoint?.transform = .identity
		})
		
		self.videoPlayer?.currentItem?.forwardPlaybackEndTime = endPoint.time
		videoPlayer?.play()
		touchOffset = nil
		activePoint = nil
		inactivePoint = nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
