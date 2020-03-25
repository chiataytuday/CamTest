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
	let device: AVCaptureDevice
	private let layer: AVCaptureVideoPreviewLayer
	let output: AVCaptureMovieFileOutput
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
		do {
			let deviceInput = try AVCaptureDeviceInput(device: device)
			session.addInput(deviceInput)
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			session.addInput(audioInput)
			
			session.addOutput(output)
			output.connection(with: .video)?.preferredVideoStabilizationMode = .auto
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
	
	func startSession() {
		session.startRunning()
	}
	
	func stopSession() {
		session.stopRunning()
	}
	
	func startRecording(_ delegate: AVCaptureFileOutputRecordingDelegate) {
		output.startRecording(to: path, recordingDelegate: delegate)
	}
	
	func stopRecording() {
		output.stopRecording()
	}
	
	
	func setExposure(_ point: CGPoint, _ mode: AVCaptureDevice.ExposureMode) {
		do {
			try device.lockForConfiguration()
			device.exposurePointOfInterest = layer.captureDevicePointConverted(fromLayerPoint: point)
			device.exposureMode = mode
			device.unlockForConfiguration()
		} catch {}
	}
	
	func setExposure(_ mode: AVCaptureDevice.ExposureMode) {
		do {
			try device.lockForConfiguration()
			device.exposureMode = mode
			device.unlockForConfiguration()
		} catch {}
	}
	
	func setTargetBias(_ bias: Float) {
		do {
			try device.lockForConfiguration()
			device.setExposureTargetBias(bias, completionHandler: nil)
			device.unlockForConfiguration()
		} catch {}
	}
	
	func setLensPosition(_ pos: Float) {
		do {
			try device.lockForConfiguration()
			device.setFocusModeLocked(lensPosition: pos, completionHandler: nil)
			device.unlockForConfiguration()
		} catch {}
	}
	
	func setTorch(_ mode: AVCaptureDevice.TorchMode) {
		do {
			try device.lockForConfiguration()
			device.torchMode = mode
			device.unlockForConfiguration()
		} catch {}
	}
}
