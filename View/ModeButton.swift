//
//  ModeButton.swift
//  Flaneur
//
//  Created by debavlad on 15.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

class ModeButton: UIView {
	
	let circleView: UIImageView = {
		let image = UIImage(systemName: "smallcircle.fill.circle")
		let imageView = UIImageView(image: image)
		imageView.frame.size = CGSize(width: 100, height: 100)
		imageView.contentMode = .center
		imageView.tintColor = .white
		return imageView
	}()
	
	var photoBtn, videoBtn: UIButton!
	var stackView: UIStackView!
	
	var photoIsEnabled = false
	
	init() {
		super.init(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
		circleView.center = center
		clipsToBounds = false
		addSubview(circleView)
		backgroundColor = .black
		
		photoBtn = getButton("camera.fill", "Photo")
		videoBtn = getButton("video.fill", "Video")
		videoBtn.backgroundColor = .systemGray5
		stackView = UIStackView(arrangedSubviews: [photoBtn, videoBtn])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.alpha = 0
		addSubview(stackView)
		stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.stackView.transform = .identity
			self.circleView.transform = CGAffineTransform(scaleX: 4, y: 4)
			self.transform = CGAffineTransform(translationX: -self.stackView.frame.width/2, y: -self.stackView.frame.height/1.5)
			self.circleView.alpha = 0
			self.stackView.alpha = 1
		})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: stackView) else { return }
		if photoBtn.frame.contains(touch) {
			photoBtn.backgroundColor = .systemGray5
			videoBtn.backgroundColor = .systemGray6
		} else if videoBtn.frame.contains(touch) {
			videoBtn.backgroundColor = .systemGray5
			photoBtn.backgroundColor = .systemGray6
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			self.circleView.transform = .identity
			self.circleView.alpha = 1
			self.transform = .identity
			self.stackView.alpha = 0
		})
	}
	
	private func getButton(_ symbolName: String, _ text: String) -> UIButton {
		let btn = UIButton(type: .custom)
		btn.setImage(UIImage(systemName: symbolName), for: .normal)
		btn.setTitle(text, for: .normal)
		btn.setTitleColor(.systemGray, for: .normal)
		btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .light)
		btn.tintColor = .systemGray
		btn.backgroundColor = .systemGray6
		btn.imageEdgeInsets.left -= 8
		btn.titleEdgeInsets.right -= 8
		btn.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			btn.widthAnchor.constraint(equalToConstant: 110),
			btn.heightAnchor.constraint(equalToConstant: 45)
		])
		clipsToBounds = true
		return btn
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
