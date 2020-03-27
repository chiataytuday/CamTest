//
//  Settings.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import AVFoundation

class Settings {
	static let shared = Settings()
	
	var exposureMode: AVCaptureDevice.ExposureMode
	var torchEnabled: Bool
	
	private init() {
		exposureMode = .continuousAutoExposure
		torchEnabled = false
	}
}
