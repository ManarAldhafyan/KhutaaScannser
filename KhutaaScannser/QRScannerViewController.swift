//
//  QRScannerViewController.swift
//  KhutaaScannser
//
//  Created by manar . on 24/09/2022.
//



import UIKit
import AVFoundation
import FirebaseDatabase
import Firebase
import FirebaseStorage

class QRScannerViewController: UIViewController {
    var firebaseDatabaseReference = Database.database().reference()
    var ref:DatabaseReference!
    let db = Firestore.firestore()
    var reward:RewardsStruct!
    

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var topBar: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession.startRunning()
            
            // Move the message label and top bar to the front
            view.bringSubviewToFront(messageLabel)
            view.bringSubviewToFront(topBar)
            
            // Initialize QR Code Frame to highlight the QR Code
            qrCodeFrameView = UIView()
            
            if let qrcodeFrameView = qrCodeFrameView {
                qrcodeFrameView.layer.borderColor = UIColor.yellow.cgColor
                qrcodeFrameView.layer.borderWidth = 2
                view.addSubview(qrcodeFrameView)
                view.bringSubviewToFront(qrcodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue anymore
            print(error)
            return
        }
        
    }
    
    
    
    func presentInfo(sender: Any?) {
    
        print("---------------- Entered presentInfo func -------------------")
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewCodeInfoSBI") as? ViewCodeInfoVC
        vc?.RTitle = reward.RewardTitle
        vc?.RDesc = reward.RewardTitle
        vc?.RDiscount = reward.RewardDiscount
        self.present(vc!, animated: true, completion: nil)
        //navigationController?.pushViewController(vc!, animated: true)

        
        
//        let popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewCodeInfoSBI") as! ViewCodeInfoVC
//            popUpVC.RTitle = reward.RewardTitle
//            popUpVC.RDesc = reward.RewardTitle
//            popUpVC.RDiscount = reward.RewardDiscount
//
//        self.addChild(popUpVC)
//            popUpVC.view.frame = self.view.frame
//            self.view.addSubview(popUpVC.view)
//            popUpVC.didMove(toParent: self)

        
    }
    
    
}


extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            if metadataObj.stringValue != nil {
                let QRnumber = metadataObj.stringValue ?? ""
            
                db.collection("AllQRCodes").getDocuments(completion: {snapshot,error in
                    if error != nil {
                        print("error retrive")
                        print(error)
                    }else{
                        for document in (snapshot?.documents)!{
//                            print(document.documentID)

                            if String(document.documentID) == QRnumber{
//                                    print("the cur key is:   ")
//                                    print(document.documentID)
                                    
                                
                                self.db.collection("AllQRCodes").document(QRnumber).setData( ["isScanned": true], merge: true)
                    
                                let ReciverID = document.data()["ReciverID"] as! String
                                let RewardKey = document.data()["RewardKey"] as! String
                                let RewardTitle = document.data()["RewardTitle"] as! String
                                let RewardDiscount = document.data()["RewardDiscount"] as! String
                                let RewardDesc = document.data()["RewardDesc"] as! String
                                
                                let rewardOBJ = RewardsStruct( ReciverID : ReciverID, RewardKey: RewardKey , RewardTitle: RewardTitle , RewardDiscount: RewardDiscount, RewardDesc: RewardDesc )
                                
                                self.reward = rewardOBJ
                                let sender : RewardsStruct = rewardOBJ
                                    
//                                    print("resciver id is  " + ReciverID)
//                                    print("RewardKey is "+RewardKey)
                                    
                                    self.db.collection("users").document(ReciverID).collection("UserRewards").document(RewardKey).setData( ["isScanned": true], merge: true)
                                
                               
                                    
                                    print("Scanned successfully")
                                    self.messageLabel.text = "Succefully Scanned"
                               
                                self.db.collection("users").document(ReciverID).collection("UserRewards").document(RewardKey).delete()
                                
                                self.db.collection("AllQRCodes").document(QRnumber).delete()
                                
                                self.presentInfo(sender: sender)
                                

                                    
                                    break
                                    
                                } // end if key
                                
                                else{
                                    self.messageLabel.text = "The QR code is not valid"
                                }
                             // end keys loop
                            
                        }// end documents for loop
                    } // end else in line 136
                    
                })//end documents completuin
                
                
                
                
                
            } //end (if metadataObj.stringValue) line 129
         } // end (if  supportedCodeTypes.contains) line 125
     } // end meteadata func
    
 }
                             
