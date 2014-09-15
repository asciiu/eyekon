//
//  CaptureSessionManager.swift
//  Spotter
//
//  Created by LV426 on 9/14/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import AVFoundation

var kImageCapturedSuccessfully = "imageCapturedSuccessfully"

class CaptureSessionManager: NSObject {
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var stillImage: UIImage?
    
    override init() {
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
    }
    
    deinit {
        self.captureSession!.stopRunning()
        
        self.previewLayer = nil
        self.captureSession = nil
    }
    
    func addStillImageOutput() {
        self.stillImageOutput = AVCaptureStillImageOutput()
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        self.stillImageOutput?.outputSettings = outputSettings
        
        
        var videoConnection: AVCaptureConnection?
        for connection: AVCaptureConnection in self.stillImageOutput!.connections as [AVCaptureConnection] {
            for port: AVCaptureInputPort in connection.inputPorts as [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection
                    break
                }
            }
            
            if videoConnection != nil {
                break
            }
        }
        
        self.captureSession?.addOutput(self.stillImageOutput!)
        //self.captureSession!.startRunning()
    }
    
    func addVideoPreviewLayer() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    func addVideoInput() {
        
        let videoDevice: AVCaptureDevice? = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as AVCaptureDevice?
        
        // is the camera available?
        if videoDevice != nil {
            var error: NSError?
            
            let videoIn: AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as AVCaptureDeviceInput
            
            if error != nil {
                println("Couldn't create video input")
            } else {
                if( self.captureSession!.canAddInput(videoIn)) {
                    self.captureSession!.addInput(videoIn)
                } else {
                    println("Couldn't add video input")
                }
            }
        }
    }
    
    func captureStillImage() {
        
        var videoConnection: AVCaptureConnection?
        
        for connection in self.stillImageOutput!.connections {
            for port in connection.inputPorts as [AVCaptureInputPort] {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            
            if videoConnection != nil {
                break
            }
        }
        
        self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection!, completionHandler: { (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            
            if error != nil {
                println("Capture still image failed \(error.localizedDescription)")
            } else if imageDataSampleBuffer != nil {
                let imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                self.stillImage = UIImage(data: imageData)
                NSNotificationCenter.defaultCenter().postNotificationName(kImageCapturedSuccessfully, object: nil)
            }
        })
    }
}
