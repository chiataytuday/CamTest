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

final class ModeButton: UIView {
	
	let icon: UIImageView = {
		let img = UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
		let imgView = UIImageView(image: img)
		imgView.translatesAutoresizingMaskIntoConstraints = false
		imgView.isUserInteractionEnabled = false
		imgView.contentMode = .center
		imgView.tintColor = .systemGray2
		return imgView
	}()
	
	let backgroundView: UIView = {
		let view = UIView()
		view.backgroundColor = .systemGray6
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 14
		return view
	}()
	
	private var stackView: UIView!
	private var photoBtn, videoBtn: UIButton!
	private var chosenBtn: UIButton?
	var didChange: ((Mode) -> ())?
	var willSelect: (() -> ())?
	
	private let buttonWidth: CGFloat = 106
	private let buttonHeight: CGFloat = 43
	
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
		addSubview(backgroundView)
		NSLayoutConstraint.activate([
			backgroundView.widthAnchor.constraint(equalToConstant: 43),
			backgroundView.heightAnchor.constraint(equalToConstant: 28),
			backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
			backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
		
		backgroundView.addSubview(icon)
		NSLayoutConstraint.activate([
			icon.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
			icon.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
		])
		
		photoBtn = modeButton("camera.fill", "Photo")
		videoBtn = modeButton("video.fill", "Video")
		chosenBtn = photoBtn
		chosenBtn?.backgroundColor = .systemGray5

		stackView = UIView(frame: .zero)
		stackView.addSubview(videoBtn)
		stackView.addSubview(photoBtn)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
		stackView.layer.cornerRadius = 16
		stackView.clipsToBounds = true
		stackView.alpha = 0
		
		addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.widthAnchor.constraint(equalToConstant: buttonWidth),
			stackView.heightAnchor.constraint(equalToConstant: buttonHeight*2),
			stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
			videoBtn.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
			videoBtn.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
			photoBtn.bottomAnchor.constraint(equalTo: stackView.centerYAnchor),
			photoBtn.centerXAnchor.constraint(equalTo: stackView.centerXAnchor)
		])
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		willSelect?()
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
		UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
			self.stackView.isHidden = false
			self.stackView.transform = .identity
			self.backgroundView.transform = CGAffineTransform(scaleX: 2, y: 2)
			self.transform = CGAffineTransform(translationX: -106/2.5, y: 86/1.25)
			self.backgroundView.alpha = 0
			self.stackView.alpha = 1
		})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: stackView) else { return }
		if photoBtn.frame.contains(touch) && chosenBtn != photoBtn {
			chosenBtn = photoBtn
			UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
			photoBtn.backgroundColor = .systemGray5
			videoBtn.backgroundColor = .systemGray6
		} else if videoBtn.frame.contains(touch) && chosenBtn != videoBtn {
			chosenBtn = videoBtn
			UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
			videoBtn.backgroundColor = .systemGray5
			photoBtn.backgroundColor = .systemGray6
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let chosenMode: Mode = chosenBtn == photoBtn ? .photo : .video
		didChange?(chosenMode)
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			self.backgroundView.transform = .identity
			self.backgroundView.alpha = 1
			self.backgroundView.isHidden = false
			self.transform = .identity
			self.stackView.alpha = 0
		})
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
	private func modeButton(_ symbolName: String, _ text: String) -> UIButton {
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
			btn.widthAnchor.constraint(equalToConstant: buttonWidth),
			btn.heightAnchor.constraint(equalToConstant: buttonHeight)
		])
		return btn
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
