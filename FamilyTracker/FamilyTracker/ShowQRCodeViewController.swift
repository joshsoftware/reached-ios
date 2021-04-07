//
//  ShowQRCodeViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 16/03/21.
//

import UIKit

class ShowQRCodeViewController: UIViewController {
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var viewGroupBtn: UIButton!
    
    var groupId: String = ""
    var iIsFromCreateGroupFlow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        createBarcode()
    }
    
    private func setUp() {
        if iIsFromCreateGroupFlow {
            viewGroupBtn.isHidden = false
        } else {
            viewGroupBtn.isHidden = true
        }
    }
    
    private func createBarcode() {
        // Get data from the string
        let data = groupId.data(using: String.Encoding.ascii)
        // Get a QR CIFilter
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return }
        // Input the data
        qrFilter.setValue(data, forKey: "inputMessage")
        // Get the output image
        guard let qrImage = qrFilter.outputImage else { return }
        // Scale the image
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage.transformed(by: transform)
        // Do some processing to get the UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else { return }
        let processedImage = UIImage(cgImage: cgImage)
        qrCodeImageView.image = processedImage
    }
    
    
    @IBAction func viewGroupBtnAction(_ sender: UIButton) {
        if let vc = UIStoryboard.sharedInstance.instantiateViewController(withIdentifier: "GroupListViewController") as? GroupListViewController {
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
}
