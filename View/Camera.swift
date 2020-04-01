//
//  Camera.swift
//  Flaneur
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class Camera {
	
	static let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("out").appendingPathExtension("mp4")
	let recordURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("rec").appendingPathExtension("mp4")
	
	let device: AVCaptureDevice
	let output: AVCaptureMovieFileOutput
	private let session: AVCaptureSession
	private let layer: AVCaptureVideoPreviewLayer
	private var path: URL!
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1.5))
		bar.backgroundColor = Colors.gray9
		bar.alpha = 0.5
		bar.layer.cornerRadius = 1.25
		return bar
	}()
	
	private(set) var isRecording = false
	var durationAnim: UIViewPropertyAnimator?
	private var timer: Timer?
	
	
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
		
		layer = AVCaptureVideoPreviewLayer(session: session)
		layer.videoGravity = .resizeAspectFill
		layer.connection?.videoOrientation = .portrait
		
		session.commitConfiguration()
		session.startRunning()
	}
	
	func attach(to view: UIView) {
		layer.frame = view.frame
		view.layer.insertSublayer(layer, at: 0)
		
		view.addSubview(durationBar)
		durationBar.frame.origin.y = view.frame.height - durationBar.frame.height
	}
	
	func startSession() {
		session.startRunning()
	}
	
	func stopSession() {
		session.stopRunning()
	}
	
	func startRecording(_ delegate: AVCaptureFileOutputRecordingDelegate?) {
		isRecording = true
		output.startRecording(to: recordURL, recordingDelegate: delegate!)
		
		durationAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: {
			self.durationBar.frame.size.width = self.layer.frame.width
		})
	}
	
	func stopRecording() {
		isRecording = false
		output.stopRecording()
		
		timer?.invalidate()
		durationAnim?.stopAnimation(true)
		durationAnim = nil
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.durationBar.frame.size.width = 0
		})
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
