//
//  PhotoButton.swift
//  Flaneur
//
//  Created by debavlad on 13.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class PhotoButton: CustomButton {
	
	private let circleView: UIView = {
		let circle = UIView()
		circle.translatesAutoresizingMaskIntoConstraints = false
		circle.isUserInteractionEnabled = false
		circle.backgroundColor = .systemGray
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
		square.backgroundColor = .systemGray
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
		
		addSubview(circleView)
		NSLayoutConstraint.activate([
			circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
			circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		circleView.addSubview(pulsatingView)
		NSLayoutConstraint.activate([
			pulsatingView.centerXAnchor.constraint(equalTo: centerXAnchor),
			pulsatingView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
