//
//  StatusBar.swift
//  Flaneur
//
//  Created by debavlad on 08.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

final class StatusBar : UIStackView {
	
	private var dict = [String : UIButton]()
	
	init(contentsOf imageNames: [String]) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		heightAnchor.constraint(equalToConstant: 25).isActive = true
		distribution = .equalCentering
		spacing = 6
		
		for imageName in imageNames {
			let item = createItem(imageName)
			dict[imageName] = item
			addArrangedSubview(item)
		}
	}
	
	private func createItem(_ imageName: String) -> UIButton {
		let image = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14))
		let item = UIButton(type: .custom)
		item.backgroundColor = .systemYellow
		item.tintColor = .black
		item.layer.cornerRadius = 12
		item.isUserInteractionEnabled = false
		item.setImage(image, for: .normal)
		item.isHidden = true
		NSLayoutConstraint.activate([
			item.heightAnchor.constraint(equalToConstant: 25),
			item.widthAnchor.constraint(equalToConstant: 40)
		])
		return item
	}
	
	func setVisiblity(for imageName: String, _ isVisible: Bool) {
		guard dict.keys.contains(imageName) else { return }
		
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: [], animations: {
			self.dict[imageName]?.isHidden = isVisible
			self.layoutIfNeeded()
		})
		
		let args: (TimeInterval, UIView.AnimationCurve, CGFloat) = isVisible ? (0.075, .easeIn, 0) : (0.1, .linear, 1)
		UIViewPropertyAnimator(duration: args.0, curve: args.1) {
			self.dict[imageName]?.alpha = args.2
		}.startAnimation()
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
