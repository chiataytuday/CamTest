//
//  Camera.swift
//  Amble
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class Camera {
	private let session: AVCaptureSession
	private let device: AVCaptureDevice
	private let layer: AVCaptureVideoPreviewLayer
	private let output: AVCaptureMovieFileOutput
	private let path: URL
	
	init() {
		session = AVCaptureSession()
		session.beginConfiguration()
		session.automaticallyConfiguresApplicationAudioSession = false
		session.sessionPreset = .hd1920x1080
		
		device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first!
		do {
			try device.lockForConfiguration()
			device.setFocusModeLocked(lensPosition: 0.4, completionHandler: nil)
			device.setExposureTargetBias(-0.5, completionHandler: nil)
			device.unlockForConfiguration()
		} catch {}
		
		output = AVCaptureMovieFileOutput()
		output.movieFragmentInterval = .invalid
		output.connection(with: .video)?.preferredVideoStabilizationMode = .cinematic
		do {
			session.addOutput(output)
			let deviceInput = try AVCaptureDeviceInput(device: device)
			session.addInput(deviceInput)
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			session.addInput(audioInput)
		} catch {}
		
		let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		path = url.appendingPathComponent("output").appendingPathExtension("mp4")
		
		layer = AVCaptureVideoPreviewLayer(session: session)
		layer.videoGravity = .resizeAspectFill
		layer.connection?.videoOrientation = .portrait
		
		session.commitConfiguration()
		session.startRunning()
	}
	
	func attachLayer(to view: UIView) {
		layer.frame = view.frame
		view.layer.insertSublayer(layer, at: 0)
	}
}
