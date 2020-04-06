//
//  RecordButton.swift
//  Flaneur
//
//  Created by debavlad on 05.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class RecordButton : SquareButton {
	
	private let redCircle: UIView = {
		let circle = UIView()
		circle.translatesAutoresizingMaskIntoConstraints = false
		circle.isUserInteractionEnabled = false
		circle.backgroundColor = Colors.red
		circle.layer.cornerRadius = 10
		NSLayoutConstraint.activate([
			circle.widthAnchor.constraint(equalToConstant: 20),
			circle.heightAnchor.constraint(equalToConstant: 20)
		])
		return circle
	}()
	
	private let pulsatingSquare: UIView = {
		let square = UIView()
		square.translatesAutoresizingMaskIntoConstraints = false
		square.isUserInteractionEnabled = false
		square.backgroundColor = .systemRed
		square.layer.cornerRadius = 6
		NSLayoutConstraint.activate([
			square.widthAnchor.constraint(equalToConstant: 20),
			square.heightAnchor.constraint(equalToConstant: 20)
		])
		square.alpha = 0.3
		return square
	}()
	
	
	init(size: CGSize, radius: CGFloat) {
		super.init(size: size)
		layer.cornerRadius = radius
		clipsToBounds = true
		
		addSubview(redCircle)
		NSLayoutConstraint.activate([
			redCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		redCircle.addSubview(pulsatingSquare)
		NSLayoutConstraint.activate([
			pulsatingSquare.centerXAnchor.constraint(equalTo: centerXAnchor),
			pulsatingSquare.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}
	
	@objc override func touchDown() {
		redCircle.transform = .identity
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.25)
		UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: { [weak self] in
			self?.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75)
		})
	}
	
	func touchUp(camIsRecording: Bool) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.35)
		
		let radius: CGFloat = camIsRecording ? 10 : 3.25
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: { [weak self] in
			self?.redCircle.transform = CGAffineTransform.identity
			self?.redCircle.layer.cornerRadius = radius
		})
		
		if !camIsRecording {
			UIView.animate(withDuration: 0.65, delay: 0, options: [.curveEaseOut, .repeat, .autoreverse], animations: { [weak self] in
				self?.pulsatingSquare.transform = CGAffineTransform(scaleX: 2, y: 2)
			})
		} else {
			pulsatingSquare.layer.removeAllAnimations()
			UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: { [weak self] in
				self?.pulsatingSquare.transform = .identity
			})
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
