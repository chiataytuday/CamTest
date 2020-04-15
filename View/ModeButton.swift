//
//  ModeButton.swift
//  Flaneur
//
//  Created by debavlad on 15.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

enum Mode {
	case video, photo
}

class ModeButton: UIView {
	
	let circleView: UIImageView = {
		let image = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
		let imageView = UIImageView(image: image)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.isUserInteractionEnabled = false
		imageView.contentMode = .center
		imageView.tintColor = .systemGray6
		return imageView
	}()
	
	private var photoBtn, videoBtn: UIButton!
	private var stackView: UIView!
	private var chosenBtn: UIButton?
	var delegate: ((Mode) -> ())?
	
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: 70),
			heightAnchor.constraint(equalToConstant: 70)
		])
		clipsToBounds = false
		backgroundColor = .clear
		setupSubviews()
	}
	
	private func setupSubviews() {
		addSubview(circleView)
		NSLayoutConstraint.activate([
			circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
			circleView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		photoBtn = getButton("camera.fill", "Photo")
		videoBtn = getButton("video.fill", "Video")
		chosenBtn = videoBtn
		videoBtn.backgroundColor = .systemGray5
		stackView = UIView(frame: .zero)
		stackView.addSubview(videoBtn)
		stackView.addSubview(photoBtn)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
		stackView.clipsToBounds = true
		stackView.layer.cornerRadius = 16
		addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.widthAnchor.constraint(equalToConstant: 106),
			stackView.heightAnchor.constraint(equalToConstant: 86),
			stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
			videoBtn.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
			videoBtn.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
			photoBtn.bottomAnchor.constraint(equalTo: stackView.centerYAnchor),
			photoBtn.centerXAnchor.constraint(equalTo: stackView.centerXAnchor)
		])
		stackView.alpha = 0
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
			self.stackView.isHidden = false
			self.stackView.transform = .identity
			self.circleView.transform = CGAffineTransform(scaleX: 4, y: 4)
			self.transform = CGAffineTransform(translationX: -106/2.5, y: 86/1.25)
			self.circleView.alpha = 0
			self.stackView.alpha = 1
		})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: stackView) else { return }
		if photoBtn.frame.contains(touch) && chosenBtn != photoBtn {
			chosenBtn = photoBtn
			UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
			photoBtn.backgroundColor = .systemGray5
			videoBtn.backgroundColor = .systemGray6
		} else if videoBtn.frame.contains(touch) && chosenBtn != videoBtn {
			chosenBtn = videoBtn
			UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.3)
			videoBtn.backgroundColor = .systemGray5
			photoBtn.backgroundColor = .systemGray6
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let chosenMode: Mode = chosenBtn == photoBtn ? .photo : .video
		delegate?(chosenMode)
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			self.circleView.transform = .identity
			self.circleView.alpha = 1
			self.circleView.isHidden = false
			self.transform = .identity
			self.stackView.alpha = 0
		})
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
	private func getButton(_ symbolName: String, _ text: String) -> UIButton {
		let btn = UIButton(type: .custom)
		btn.setImage(UIImage(systemName: symbolName), for: .normal)
		btn.setTitle(text, for: .normal)
		btn.setTitleColor(.systemGray, for: .normal)
		btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .light)
		btn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 17), forImageIn: .normal)
		btn.tintColor = .systemGray
		btn.backgroundColor = .systemGray6
		btn.imageEdgeInsets.left -= 8
		btn.titleEdgeInsets.right -= 8
		btn.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			btn.widthAnchor.constraint(equalToConstant: 106),
			btn.heightAnchor.constraint(equalToConstant: 43)
		])
		return btn
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
