//
//  ViewController.swift
//  RTObjectRecognition
//
//  Created by Raghu Sairam on 19/01/19.
//  Copyright © 2019 Raghu Sairam. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let predictionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }

        captureSession.addInput(input)

        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutPut = AVCaptureVideoDataOutput()
        dataOutPut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        captureSession.addOutput(dataOutPut)
        
        setupLabelLayout()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        //guard let model = try? VNCoreMLModel(for: SqueezeNet().model) else {return}
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }

        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            if let err = err {
                print(err)
            }

            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }

            guard let observation = results.first else { return }
            guard let percentage = self.roundingValue(value: observation.confidence * 100) else { return }
            DispatchQueue.main.async {
                self.predictionLabel.text = "\(observation.identifier) \(percentage)%"
            }
            
        }

        try? VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    fileprivate func roundingValue (value: Float ) -> String?{
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber)
    }
    
    fileprivate func setupLabelLayout() {
        view.addSubview(predictionLabel)
        view.backgroundColor = .white
        predictionLabel.translatesAutoresizingMaskIntoConstraints = false
        predictionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        predictionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        predictionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        predictionLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

}

