//
//  PlayerController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

//view.addSubview(startButton)
//NSLayoutConstraint.activate([
//	startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
//	startButton.leadingAnchor.constraint(equalTo: view.centerXAnchor),
//	startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
//	startButton.heightAnchor.constraint(equalToConstant: 50)
//])

class PlayerController: UIViewController {
	
	var url: URL!
	
	private let removeButton: UIButton = {
		let button = UIButton(type: .custom)
		button.layer.cornerRadius = 26.25
		button.backgroundColor = .white
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .medium), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.tintColor = .systemRed
		return button
	}()
	
	private let saveButton: UIButton = {
		let button = UIButton(type: .custom)
		button.layer.cornerRadius = 26.25
		button.backgroundColor = .white
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .medium), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.tintColor = .systemGreen
		return button
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.layer.cornerRadius = 6
		view.clipsToBounds = true
		
		let item = AVPlayerItem(url: url)
		let player = AVPlayer(playerItem: item)
		player.actionAtItemEnd = .none
		NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
		
		
		let layer = AVPlayerLayer(player: player)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(layer)
		player.play()
		
		let offset = view.frame.width/3 - 52.5/4
		
		view.addSubview(saveButton)
		NSLayoutConstraint.activate([
			saveButton.heightAnchor.constraint(equalToConstant: 52.5),
			saveButton.widthAnchor.constraint(equalToConstant: 52.5),
			saveButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -77.5),
			saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		
		view.addSubview(removeButton)
		NSLayoutConstraint.activate([
			removeButton.heightAnchor.constraint(equalToConstant: 52.5),
			removeButton.widthAnchor.constraint(equalToConstant: 52.5),
			removeButton.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -77.5),
			removeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset),
		])
	}
	
	@objc private func playerItemDidReachEnd(notification: Notification) {
		if let playerItem = notification.object as? AVPlayerItem {
			playerItem.seek(to: .zero, completionHandler: nil)
		}
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(1, .present)
	}
}
