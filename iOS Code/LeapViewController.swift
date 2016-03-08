//
//  ViewController.swift
//  SimpleTest
//
//  Created by Dalton Cherry on 8/12/14.
//  Copyright (c) 2014 vluxe. All rights reserved.
//

import UIKit

class LeapViewController: UIViewController, WebSocketDelegate {
    
    var socket = WebSocket(url: NSURL(string: "ws://localhost:6437/")!, protocols: ["chat", "superchat"])
    
    var awsIoTConnectionManager = AWSIoTConnectionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        awsIoTConnectionManager.initIoT()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "awsIoTConnected", name: "awsiotconnected", object: nil)
        
        awsIoTConnectionManager.connect()
    }
    
    func awsIoTConnected() {
        
        self.subscribeToAWSIoT()
        
        socket.delegate = self
        socket.connect()
        
    }
    
    // MARK: Websocket Delegate Methods.
    
    func websocketDidConnect(ws: WebSocket) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        //print("Received text: \(text)")
        
        self.parseLeapData(text)
        
        //self.publishToAWSIoT(text)
    }
    
    func websocketDidReceiveData(ws: WebSocket, data: NSData) {
        //print("Received data: \(data.length)")
    }
    
    // MARK: Write Text Action
    
    @IBAction func writeText(sender: UIBarButtonItem) {
        socket.writeString("hello there!")
    }
    
    // MARK: Disconnect Action
    
    @IBAction func disconnect(sender: UIBarButtonItem) {
        if socket.isConnected {
            sender.title = "Connect"
            socket.disconnect()
        } else {
            sender.title = "Disconnect"
            socket.connect()
        }
    }
    
    func parseLeapData(text:String) {
        
        //print(text)
        
        var x:Float = 0.0
        var y:Float = 0.0
        var z:Float = 0.0
        
        if let leapData = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            
            do {
                let dataObject:AnyObject =  try NSJSONSerialization.JSONObjectWithData(leapData,options:NSJSONReadingOptions.MutableContainers)  as! Dictionary<String,AnyObject>
                if let hands = dataObject["hands"] as? [Dictionary<String,AnyObject>] {
                    for hand in hands {
                        if let direction = hand["direction"] as? [Float] {
                            x = direction[0]
                        }
                        if let palmNormal = hand["palmNormal"] as? [Float] {
                            y = palmNormal[1]
                            z = palmNormal[2]
                            //print ("Here")
                            print("Coords: \(x) : \(y) : \(z) ")
                        }
                        /*
                        set_xAxis = int((600 - ((xAxis / 1.98) * 450)) - 150 )
                        set_yAxis = int(375 - (100 * (yAxis / 360)))
                        set_zAxis = int(275 + (((zAxis + 50) / 200) * 200))
                        
                        tev_json_obj = json.dumps({'frameId':frame.id, 'coordinates':{'xAxis':set_xAxis,'yAxis':set_yAxis, 'zAxis': set_zAxis, 'clockwiseness': clockwiseness}})
                        print(tev_json_obj)
                        
                        counter = str(frame.id)
                        counter = counter[-1:]
                        if counter == '1' and self.mqttc != None:
                        self.mqttc.publish(AWS_IOT_TOPIC, tev_json_obj, 0, False)
                        
                        
                        */
                        let xAxis = Int((600 - ((x / 1.98) * 450)) - 150 )
                        let yAxis = Int(375 - (100 * (y / 360)))
                        let zAxis = Int(275 + (((z + 50) / 200) * 200))
                        
                        if let theId = dataObject["id"] as? Int {
                            let theIdString =  String(theId)
                            //var substring1 = theIdString.substringFromIndex(theIdString.endIndex)
                            //print(theIdString)
                        }
                        //print("Coords: \(xAxis) : \(yAxis) : \(zAxis) ")
                    }
                }
            }
            catch _ {
                print("Error")
            }
        }
    }
    
    // AWS IoT stuff
    
    func publishToAWSIoT(text:String) {
        
        let iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        
        iotDataManager.publishString(text, onTopic:"leap/motion")
        
        //print ("Published to AWS IoT :\(text)")
        
    }
    
    func subscribeToAWSIoT() {
        
        let iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        
        iotDataManager.subscribeToTopic("leap/motion", qos: 0, messageCallback: {
            (payload) ->Void in
            let stringValue = NSString(data: payload, encoding: NSUTF8StringEncoding)!
            
            print("Received from AWS IoT: \(stringValue)")
        } )
    }
}

