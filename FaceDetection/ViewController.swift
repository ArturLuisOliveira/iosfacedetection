//
//  ViewController.swift
//  FaceDetection
//
//  Created by Artur Luis on 30/11/21.
//

import UIKit
import AVKit
import Vision

class ViewController:  UIViewController {
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoDataOutputQueue: DispatchQueue?
    private var rectangle = CGRect()
    private var clownView: UIImageView = UIImageView(image: UIImage(named: "clown"))
    
    private var aspectRatio: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        aspectRatio = clownView.bounds.width / clownView.bounds.height
        self.view.addSubview(self.clownView)
    }
    
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // the user has already authorized to access the camera.
            self.setupCaptureSession()
            
        case .notDetermined: // the user has not yet asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted { // if user has granted to access the camera.
                    print("the user has granted to access the camera")
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                } else {
                    print("the user has not granted to access the camera")
                    self.handleDismiss()
                }
            }
            
        case .denied:
            print("the user has denied previously to access the camera.")
            self.handleDismiss()
            
        case .restricted:
            print("the user can't give camera access due to some restriction.")
            self.handleDismiss()
            
        default:
            print("something has wrong due to we can't access the camera.")
            self.handleDismiss()
        }
    }
    
    private func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                self.configureVideoDataOutput(for: input.device, captureSession: captureSession)
            } catch let error {
                print("Failed to set input device with error: \(error)")
            }
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.frame = self.view.frame
            cameraLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(cameraLayer)
            
            captureSession.startRunning()
            
        }
    }
    
    private func handleDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, captureSession: AVCaptureSession) {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        self.videoOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .down, options: [:]).perform([VNDetectFaceRectanglesRequest(completionHandler: {(req,err) in
            if err != nil {
                print("Error")
                return
            }
            guard let results = req.results as? [VNFaceObservation] else { return }
            
            results.forEach{result in
                DispatchQueue.main.async {
                    
                    
                    
                    let w = 100.0
                    let h = 100.0
                    let x = self.view.frame.width / 100 * 100 * (1 - result.boundingBox.origin.x)
                    let y = result.boundingBox.origin.y * self.view.frame.height
                    print(w,h,x,y)
                    self.clownView.frame = CGRect(x: y, y: x, width: w, height: h)
                    
                    
                }
            }
            
        })])
    }
}
