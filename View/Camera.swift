//
//  Camera.swift
//  Flaneur
//
//  Created by debavlad on 25.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

final class Camera {
	
	var captureDevice: AVCaptureDevice!
	var captureSession = AVCaptureSession()
	var durationAnim: UIViewPropertyAnimator?
	var previewView: PreviewView!
	var isRecording = false
	
	private var photoOutput = AVCapturePhotoOutput()
	private var movieFileOutput = AVCaptureMovieFileOutput()
	
	private let durationBar: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 2))
		bar.backgroundColor = .systemRed
		bar.layer.cornerRadius = bar.frame.height/2
		return bar
	}()
	
	
	init() {
		captureSession.beginConfiguration()
		captureSession.automaticallyConfiguresApplicationAudioSession = false
		captureSession.sessionPreset = .hd1920x1080
		
		captureDevice = bestDevice(in: .back)
		let audioDevice = AVCaptureDevice.default(for: .audio)
		movieFileOutput.movieFragmentInterval = .invalid
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
			if captureSession.canAddInput(deviceInput) {
				captureSession.addInput(deviceInput)
			}
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			if captureSession.canAddInput(audioInput) {
				captureSession.addInput(audioInput)
			}
			if captureSession.canAddOutput(movieFileOutput) {
				captureSession.addOutput(movieFileOutput)
			}
			if captureSession.canAddOutput(photoOutput) {
				captureSession.addOutput(photoOutput)
			}
		} catch {
			print(error.localizedDescription)
		}
		captureSession.commitConfiguration()
		
		if let connection = movieFileOutput.connection(with: .video), movieFileOutput.availableVideoCodecTypes.contains(.h264) {
			movieFileOutput.setOutputSettings([AVVideoCodecKey : AVVideoCodecType.h264], for: connection)
			connection.preferredVideoStabilizationMode = .cinematic
		}
		
		previewView = PreviewView(session: captureSession)
		previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
		previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
		
		captureSession.startRunning()
	}
	
	private func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice {
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
		[.builtInWideAngleCamera],
		mediaType: .video, position: .back)
		
		let devices = discoverySession.devices
		guard !devices.isEmpty else { fatalError("Missing capture devices.") }
		return devices.first { (device) -> Bool in
			device.position == position
		}!
	}
	
	
	func attachPreview(to view: UIView) {
		previewView.frame = view.frame
		view.insertSubview(previewView, at: 0)
		
		view.addSubview(durationBar)
		durationBar.frame.origin.y = view.frame.height - durationBar.frame.height
	}
	
	func startRecording(to recordURL: URL, _ delegate: AVCaptureFileOutputRecordingDelegate?) {
		isRecording = true
		movieFileOutput.startRecording(to: recordURL, recordingDelegate: delegate!)
		
		durationAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: { [weak self] in
			self?.durationBar.frame.size.width = self!.previewView.frame.width
		})
	}
	
	func takeShot(_ delegate: AVCapturePhotoCaptureDelegate) {
		let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
		photoOutput.capturePhoto(with: settings, delegate: delegate)
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
	
	func setExposure(_ mode: AVCaptureDevice.ExposureMode, _ point: CGPoint? = nil, _ handler: (() -> ())? = nil) {
		if captureDevice.isExposureModeSupported(mode) {
			handler?()
			do {
				try captureDevice.lockForConfiguration()
				if let p = point, captureDevice.isExposurePointOfInterestSupported {
					captureDevice.exposurePointOfInterest = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: p)
				}
				captureDevice.exposureMode = mode
				captureDevice.unlockForConfiguration()
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	func setTargetBias(_ bias: Float) {
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.setExposureTargetBias(bias, completionHandler: nil)
			captureDevice.unlockForConfiguration()
		} catch {
			print(error.localizedDescription)
		}
	}
	
	func lockLens(at pos: Float) {
		if captureDevice.isFocusModeSupported(.locked) {
			do {
				try captureDevice.lockForConfiguration()
				captureDevice.setFocusModeLocked(lensPosition: pos, completionHandler: nil)
				captureDevice.unlockForConfiguration()
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	func resetLens() {
		if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
			do {
				try captureDevice.lockForConfiguration()
				captureDevice.focusMode = .continuousAutoFocus
				captureDevice.unlockForConfiguration()
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	func torch(_ mode: AVCaptureDevice.TorchMode, _ handler: (() -> ())? = nil) {
		if captureDevice.isTorchModeSupported(mode) {
			handler?()
			do {
				try captureDevice.lockForConfiguration()
				captureDevice.torchMode = mode
				captureDevice.unlockForConfiguration()
			} catch {
				print(error.localizedDescription)
			}
		}
	}
}
