//
//  PhotoButton.swift
//  Flaneur
//
//  Created by debavlad on 14.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

final class PhotoButton: CustomButton {
	
	var cam: Camera?
	var delegate: AVCapturePhotoCaptureDelegate?
	var photoCounter = 0
	
	private var timer: Timer?
	private var blackView: UIView?
	private var longPressRecognizer: UILongPressGestureRecognizer!
	private var tracker: Tracker?
	
	private let circleView: UIView = {
		let circle = UIView()
		circle.translatesAutoresizingMaskIntoConstraints = false
		circle.isUserInteractionEnabled = false
		circle.backgroundColor = .secondaryLabel
		circle.layer.cornerRadius = 10
		NSLayoutConstraint.activate([
			circle.widthAnchor.constraint(equalToConstant: 20),
			circle.heightAnchor.constraint(equalToConstant: 20)
		])
		return circle
	}()
	
	
	init(_ size: Size, radius: CGFloat, view: UIView, tracker: Tracker, delegate: AVCapturePhotoCaptureDelegate) {
		self.delegate = delegate
		super.init(size)
		backgroundColor = .systemGray6
		layer.cornerRadius = radius
		clipsToBounds = true
		blackView = view
		self.tracker = tracker
		
		addSubview(circleView)
		NSLayoutConstraint.activate([
			circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
			circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
		longPressRecognizer.minimumPressDuration = 0.2
		addGestureRecognizer(longPressRecognizer)
	}
	
	@objc private func longPressHandler(sender: UILongPressGestureRecognizer) {
		switch (sender.state) {
			case .began:
				photoCounter = 0
				tracker?.fadeIn()
				timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true, block: { [weak self] _ in
					if self!.photoCounter + 1 < self!.tracker!.maxNumber {
						self?.takePhoto()
					}
				})
			case .ended:
				timer!.invalidate()
				timer = nil
				tracker?.fadeOut()
				touchUp()
			default:
				break
		}
	}
	
	private func takePhoto() {
		cam?.takeShot(delegate!)
		photoCounter += 1
		tracker?.setLabel(number: photoCounter)
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
	}
	
	override func touchDown() {
		autoresizesSubviews = false
		UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
			self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
		}.startAnimation()
		
		takePhoto()
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		circleView.backgroundColor = .systemGray
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [], animations: {
			self.circleView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
		})
		self.blackView!.alpha = 0.75
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
			self.blackView?.alpha = 0
		})
	}
	
	@objc func touchUp() {
		UIViewPropertyAnimator(duration: 0.15, curve: .easeOut) {
			self.transform = .identity
		}.startAnimation()
		
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
			self.circleView.backgroundColor = .secondaryLabel
			self.circleView.transform = .identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
