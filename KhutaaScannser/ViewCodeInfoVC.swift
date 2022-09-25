//
//  ViewCodeInfoVC.swift
//  KhutaaScannser
//
//  Created by manar . on 25/09/2022.
//

import UIKit

class ViewCodeInfoVC: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    
    var RTitle: String = ""
    var RDesc: String = ""
    var RDiscount: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.text = RTitle
        descTextField.text = RDesc
        codeTextField.text = RDiscount
        
        moveIn()

    }
    
    
    @IBAction func closeTapped(_ sender: Any) {
        
        print("Back to scanner")
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "QRCodeSBI") as? QRCodeViewController
        
        self.present(vc!, animated: true, completion: nil)
        //navigationController?.pushViewController(vc!, animated: true)
        
        //moveOut()

    }

    
    func moveIn() {
            self.view.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.view.alpha = 0.0

            UIView.animate(withDuration: 0.24) {
                self.view.transform = CGAffineTransform.identity
                self.view.alpha = 1.0
            }
        }

    
        func moveOut() {
            UIView.animate(withDuration: 0.24, animations: {
                self.view.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                self.view.alpha = 0.0
            }) { _ in
                self.view.removeFromSuperview()
            }
        }
    

   

}
