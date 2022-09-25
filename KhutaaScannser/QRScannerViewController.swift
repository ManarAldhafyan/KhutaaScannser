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
   // let storageRef = Storage.storage().reference()
    var ref:DatabaseReference!
    let db = Firestore.firestore()

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
    
    
    
    func presentInfo(){
        
        
        
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
                
            let ref = ref.child("AllQRCodes")
            ref.getData { [self] (error, snapshot) in
                print("snapshot \(snapshot.value as Any)")
               
                    if let value = snapshot.value as? [String: Any] {
                        for key in value.keys {

                            if key == QRnumber {
                                
                                self.ref.child("AllQRCodes").child(QRnumber).child("isScanned").setValue(true)
                                
                                
//                                print("Scanned successfully")
//                                self.messageLabel.text = "Succefully Scanned"
//                                print(key)
                                
                                let dictionary = snapshot.value as? NSDictionary
                                //print("Dictionary is:  " )
                                //print(dictionary)
                                
                                let QRnumber1 = dictionary?[QRnumber] as? [String:Any]
                                let ReciverID = QRnumber1?["ReciverID"] as? String ?? ""
                                let RewardKey = QRnumber1?["RewardKey"] as? String ?? ""
                                
                                print("resciver id is  " + ReciverID)
                                print("RewardKey is "+RewardKey)
                                
                                db.collection("users").document(ReciverID).collection("UserRewards").document(RewardKey).setData( ["isScanned": true], merge: true)
                                
                                print("Scanned successfully")
                                self.messageLabel.text = "Succefully Scanned"

                                self.ref.child("AllQRCodes").child(QRnumber).removeValue()
                                
                                break
                            
                            }
                        }
                    } else {
                        self.messageLabel.text = "The QR code is not valid"
                    
                    }
                    
                }
            }
         }
     }
    
 }
                             