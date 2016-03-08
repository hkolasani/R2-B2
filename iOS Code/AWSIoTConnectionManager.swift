class AWSIoTConnectionManager {
    
    
    var connected = false;
    
    var iotDataManager: AWSIoTDataManager!;
    var iotData: AWSIoTData!
    var iotManager: AWSIoTManager!;
    var iot: AWSIoT!

    func initIoT() {
        
        // Init IOT
        //
        // Set up Cognito
        //
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: AwsRegion, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        iotManager = AWSIoTManager.defaultIoTManager()
        iot = AWSIoT.defaultIoT()
        
        iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        iotData = AWSIoTData.defaultIoTData()
    }
    
    func connect() {
      
        
        func mqttEventCallback( status: AWSIoTMQTTStatus )
        {
            dispatch_async( dispatch_get_main_queue()) {
                print("connection status = \(status.rawValue)")
                switch(status)
                {
                case .Connecting:
                    print("Connecting..")
                    
                case .Connected:
                    print("Connected..")
                    
                    self.connected = true
                    let uuid = NSUUID().UUIDString;
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let certificateId = defaults.stringForKey( "certificateId")
                    
                    print("Using certificate:\n\(certificateId!)\n\n\nClient ID:\n\(uuid)")
                    
                    NSNotificationCenter.defaultCenter().postNotificationName( "awsiotconnected", object: self )
                    
                case .Disconnected:
                    print("Dis Connected..")
                    
                case .ConnectionRefused:
                   print("Connecttion Refused..")
                    
                case .ConnectionError:
                    print("Connection Error..")
                    
                case .ProtocolError:
                    print("Protocol Error..")
                    
                default:
                    print("Unknown State..")
                    
                }
                NSNotificationCenter.defaultCenter().postNotificationName( "connectionStatusChanged", object: self )
            }
            
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var certificateId = defaults.stringForKey( "certificateId")
            
        if (certificateId == nil) {
                print ("no certificate found.. Creating One")
                //
                // Now create and store the certificate ID in NSUserDefaults
                //
                let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]
                
                self.iotManager.createKeysAndCertificateFromCsr(csrDictionary, callback: {  (response ) -> Void in
                    
                    defaults.setObject(response.certificateId, forKey:"certificateId")
                    defaults.setObject(response.certificateArn, forKey:"certificateArn")
                    certificateId = response.certificateId
                    print("response: [\(response)]")
                    let uuid = NSUUID().UUIDString;
                    
                    let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                    attachPrincipalPolicyRequest.policyName = PolicyName
                    attachPrincipalPolicyRequest.principal = response.certificateArn
                    //
                    // Attach the policy to the certificate
                    //
                    self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest).continueWithBlock { (task) -> AnyObject? in
                        if let error = task.error {
                            print("failed: [\(error)]")
                        }
                        if let exception = task.exception {
                            print("failed: [\(exception)]")
                        }
                        print("result: [\(task.result)]")
                        //
                        // Connect to the AWS IoT platform
                        //
                        if (task.exception == nil && task.error == nil)
                        {
                            let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64(2*Double(NSEC_PER_SEC)))
                            dispatch_after( delayTime, dispatch_get_main_queue()) {
                                print("Using certificate: \(certificateId!)")
                                self.iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId,statusCallback: mqttEventCallback)
                            }
                        }
                        return nil
                    }
                } )
        }
        else {
            let uuid = NSUUID().UUIDString;
            
            // Connect to the AWS IoT service
            iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
        }
    }

    func disConnect() {
    
            print("Disconnecting...")
            
            dispatch_async( dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0) ){
                self.iotDataManager.disconnect();
            }
    }
}