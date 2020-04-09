//
//  PreviewView.swift
//  Flaneur
//
//  Created by debavlad on 09.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import AVFoundation
import UIKit

class PreviewView : UIView {
	init(session: AVCaptureSession) {
		super.init(frame: .zero)
		videoPreviewLayer.session = session
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
	
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		return layer as! AVCaptureVideoPreviewLayer
	}
}
