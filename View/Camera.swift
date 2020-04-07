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
	let captureDevice: AVCaptureDevice
	let movieFileOutput: AVCaptureMovieFileOutput
	private let captureSession: AVCaptureSession
	private var previewLayer: AVCaptureVideoPreviewLayer!
	private var path: URL!
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 2))
		bar.backgroundColor = .systemRed
		bar.layer.cornerRadius = bar.frame.height/2
		return bar
	}()
	
	private(set) var isRecording = false
	var durationAnim: UIViewPropertyAnimator?
	
	
	init(_ vc: UIViewController) {
		captureSession = AVCaptureSession()
		captureSession.beginConfiguration()
		captureSession.automaticallyConfiguresApplicationAudioSession = false
		captureSession.sessionPreset = .hd1920x1080
		
		captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first!
		
		movieFileOutput = AVCaptureMovieFileOutput()
		movieFileOutput.movieFragmentInterval = .invalid
		
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
			captureSession.addInput(deviceInput)
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			captureSession.addInput(audioInput)
			captureSession.addOutput(movieFileOutput)
		} catch {}
		
		let connection = movieFileOutput.connection(with: .video)
		connection!.preferredVideoStabilizationMode = .cinematic
		if movieFileOutput.availableVideoCodecTypes.contains(.h264) {
			movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.connection?.videoOrientation = .portrait
		
		captureSession.commitConfiguration()
		
		vc.view.addSubview(durationBar)
		durationBar.frame.origin.y = vc.view.frame.height - durationBar.frame.height
		
		DispatchQueue.global().async {
			self.captureSession.startRunning()
			DispatchQueue.main.async {
				self.previewLayer.frame = vc.view.frame
				vc.view.layer.insertSublayer(self.previewLayer, at: 0)
			}
		}
	}
	
	func attach(to view: UIView) {
		previewLayer.frame = view.frame
		view.layer.insertSublayer(previewLayer, at: 0)
		
		view.addSubview(durationBar)
		durationBar.frame.origin.y = view.frame.height - durationBar.frame.height
	}
	
	func startSession() {
		captureSession.startRunning()
	}
	
	func stopSession() {
		captureSession.stopRunning()
	}
	
	func startRecording(to recordURL: URL, _ delegate: AVCaptureFileOutputRecordingDelegate?) {
		isRecording = true
		movieFileOutput.startRecording(to: recordURL, recordingDelegate: delegate!)
		
		durationAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: { [weak self] in
			self?.durationBar.frame.size.width = self!.previewLayer.frame.width
		})
	}
	
	func stopRecording() {
		isRecording = false
		movieFileOutput.stopRecording()
		
		durationAnim?.stopAnimation(true)
		durationAnim = nil
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.durationBar.frame.size.width = 0
		})
	}
	
	
	func setExposure(_ mode: AVCaptureDevice.ExposureMode, _ point: CGPoint? = nil) {
		do {
			try captureDevice.lockForConfiguration()
			if let point = point {
				captureDevice.exposurePointOfInterest = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
			}
			captureDevice.exposureMode = mode
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	func setTargetBias(_ bias: Float) {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setExposureTargetBias(bias, completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	func setLensLocked(at pos: Float) {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setFocusModeLocked(lensPosition: pos, completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	func lensPosition() -> Float {
		return captureDevice.lensPosition
	}
	
	func setLensAuto() {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.focusMode = .continuousAutoFocus
			captureDevice.unlockForConfiguration()
		} catch {}
	}
	
	func setTorch(_ mode: AVCaptureDevice.TorchMode) {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.torchMode = mode
			captureDevice.unlockForConfiguration()
		} catch {}
	}
}
