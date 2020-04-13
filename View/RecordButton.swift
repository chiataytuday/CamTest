//
//  RecordButton.swift
//  Flaneur
//
//  Created by debavlad on 05.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class RecordButton : CustomButton {
	
	private let redView: UIView = {
		let circle = UIView()
		circle.translatesAutoresizingMaskIntoConstraints = false
		circle.isUserInteractionEnabled = false
		circle.backgroundColor = .systemRed
		circle.layer.cornerRadius = 10
		NSLayoutConstraint.activate([
			circle.widthAnchor.constraint(equalToConstant: 20),
			circle.heightAnchor.constraint(equalToConstant: 20)
		])
		return circle
	}()
	
	private let pulsatingView: UIView = {
		let square = UIView()
		square.translatesAutoresizingMaskIntoConstraints = false
		square.isUserInteractionEnabled = false
		square.backgroundColor = .systemRed
		square.layer.cornerRadius = 10
		NSLayoutConstraint.activate([
			square.widthAnchor.constraint(equalToConstant: 20),
			square.heightAnchor.constraint(equalToConstant: 20)
		])
		square.alpha = 0.3
		return square
	}()
	
	
	init(_ size: Size, radius: CGFloat) {
		super.init(size)
		backgroundColor = .systemGray6
		layer.cornerRadius = radius
		clipsToBounds = true
		
		addSubview(redView)
		NSLayoutConstraint.activate([
			redView.centerXAnchor.constraint(equalTo: centerXAnchor),
			redView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		redView.addSubview(pulsatingView)
		NSLayoutConstraint.activate([
			pulsatingView.centerXAnchor.constraint(equalTo: centerXAnchor),
			pulsatingView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}
	
	@objc override func touchDown() {
		redView.transform = .identity
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.25)
		UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.redView.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75)
		})
	}
	
	func touchUp(camIsRecording: Bool) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.35)
		
		let circleRadius: CGFloat = camIsRecording ? 10 : 3.25
		let pulsatingRadius: CGFloat = camIsRecording ? 10 : 6
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
			self.redView.transform = .identity
			self.redView.layer.cornerRadius = circleRadius
		})
		pulsatingView.layer.cornerRadius = pulsatingRadius
		
		if !camIsRecording {
			UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseOut, .repeat, .autoreverse], animations: {
				self.pulsatingView.transform = CGAffineTransform(scaleX: 2, y: 2)
			})
		} else {
			pulsatingView.layer.removeAllAnimations()
			UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: {
				self.pulsatingView.transform = .identity
			})
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
