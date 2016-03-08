//
//  ViewController.swift
//  SimpleTest
//
//  Created by Dalton Cherry on 8/12/14.
//  Copyright (c) 2014 vluxe. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    let motionManager = CMMotionManager()
    
    var awsIoTConnectionManager = AWSIoTConnectionManager()
    
    var frameId = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        awsIoTConnectionManager.initIoT()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "awsIoTConnected", name: "awsiotconnected", object: nil)

        awsIoTConnectionManager.connect()
    }
    
    func awsIoTConnected() {
        
        //self.subscribeToAWSIoT()
        
        self.startMotion()
    }
    
    func startMotion() {
        
        if motionManager.deviceMotionAvailable {
            
            motionManager.deviceMotionUpdateInterval = 0.05
            
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue(), withHandler: {
                (deviceMotion, error) -> Void in
                
                if(error == nil) {
                    self.handleDeviceMotion(deviceMotion!)
                } else {
                    //handle the error
                }
            })
        }
    }
    
    func handleDeviceMotion(deviceMotion:CMDeviceMotion) {
        
        frameId++
        
        let attitude:CMAttitude = deviceMotion.attitude
        
        //let role = attitude.roll
        let pitch = attitude.pitch
        let yaw = attitude.yaw
        let roll = attitude.roll
        
        let xAxis = Int((600 - ((yaw / 1.98) * 450)) - 150 )
        let zAxis = Int((600 - ((pitch / 1.98) * 450)) - 150 )
        //let zAxis = Int(((pitch / 1.98) * 400) + 400)
        let yAxis = Int(((roll / 1.98) * 300) + 300)
       
        
        print("x: \(xAxis), y: \(yAxis) z: \(zAxis) ")
        
        let jsonText = "{\"frameId\":\(frameId), \"coordinates\":{\"xAxis\":\(xAxis),\"yAxis\":\(yAxis), \"zAxis\": \(zAxis), \"clockwiseness\":0}}"
        
        self.publishToAWSIoT(jsonText)
    }
    
    // AWS IoT stuff
    func publishToAWSIoT(text:String) {
        
        let iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        
        iotDataManager.publishString(text, onTopic:"core/motion")
        
        print ("Published to AWS IoT :\(text)")

    }
    
    func subscribeToAWSIoT() {
        
        let iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        
        iotDataManager.subscribeToTopic("core/motion", qos: 0, messageCallback: {
            (payload) ->Void in
            let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)!
            
            print("Received from AWS IoT: \(stringValue)")
        } )
    }
}

