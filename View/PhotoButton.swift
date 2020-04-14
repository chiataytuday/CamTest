//
//  PhotoButton.swift
//  Flaneur
//
//  Created by debavlad on 14.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class PhotoButton: CustomButton {
	
	var timer: Timer?
	
	private let circleView: UIView = {
		let circle = UIView()
		circle.translatesAutoresizingMaskIntoConstraints = false
		circle.isUserInteractionEnabled = false
		circle.backgroundColor = .label
		circle.layer.cornerRadius = 10
		NSLayoutConstraint.activate([
			circle.widthAnchor.constraint(equalToConstant: 20),
			circle.heightAnchor.constraint(equalToConstant: 20)
		])
		return circle
	}()
	
	private var blackView: UIView?
	
	init(_ size: Size, radius: CGFloat, view: UIView) {
		super.init(size)
		backgroundColor = .systemGray6
		layer.cornerRadius = radius
//		clipsToBounds = true
		blackView = view
		
		addSubview(circleView)
		NSLayoutConstraint.activate([
			circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
			circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
		longPressRecognizer.minimumPressDuration = 0.35
		addGestureRecognizer(longPressRecognizer)
	}
	
	@objc func longPressHandler(sender: UILongPressGestureRecognizer) {
		switch (sender.state) {
			case .began:
				timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true, block: { (_) in
					UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
				})
			case .ended:
				timer?.invalidate()
				timer = nil
				touchUp()
			default:
				break
		}
	}
	
	override func touchDown() {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		circleView.backgroundColor = .systemGray
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [], animations: {
			self.circleView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
		})
		self.blackView?.alpha = 0.75
		UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
			self.blackView?.alpha = 0
		}.startAnimation()
	}
	
	@objc func touchUp() {
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
			self.circleView.backgroundColor = .label
			self.circleView.transform = .identity
		})
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
