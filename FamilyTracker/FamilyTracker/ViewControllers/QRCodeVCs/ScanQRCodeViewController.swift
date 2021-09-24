//
//  ScanQRCodeViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 07/04/21.
//

import UIKit

class ScanQRCodeViewController: UIViewController {

    @IBOutlet weak var scannerView: QRScannerView!
    @IBOutlet weak var closeBtn: UIButton!
    
    static var groupJoinedHandler: ((_ str: String) -> Void)?

    static func showPopup(parentVC: UIViewController){
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanQRCodeViewController") as? ScanQRCodeViewController {
            vc.modalPresentationStyle = .custom
            vc.modalTransitionStyle = .crossDissolve
            parentVC.present(vc, animated: true)
        }
   
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        scannerView.delegate = self
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    @IBAction func closeBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension ScanQRCodeViewController: QRScannerViewDelegate {
    func qrScanningDidStop() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func qrScanningDidFail() {
        self.dismiss(animated: true) {
            if let topVC = UIApplication.getTopViewController() {
                topVC.presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again", completion: {
                    
                })
            }
        }
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        self.dismiss(animated: true) {
            if let qrString = str {
                ScanQRCodeViewController.self.groupJoinedHandler?(qrString)
            }
        }
    }
   
}
