//
//  ShowQRCodeViewController.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 16/03/21.
//

import UIKit
import SVProgressHUD

class ShowQRCodeViewController: UIViewController {
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet var topView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!

    var groupId: String = ""
    var groupName: String = ""
    var iIsFromCreateGroupFlow = true

    override func viewDidLoad() {
        super.viewDidLoad()
        groupNameLabel.text = self.groupName
        createBarcode()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        topView.roundBottom(radius: 10)
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
        if iIsFromCreateGroupFlow {
            if let vc = UIStoryboard.dashboardSharedInstance.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
                self.navigationController?.pushViewController(vc, animated: false)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func shareJoinLinkBtnAction(_ sender: UIButton) {
        SVProgressHUD.show()
        JoinLinkManager.shared.createJoinLinkFor(groupId: self.groupId, groupName: self.groupName, completion: { url in
            SVProgressHUD.dismiss()
            self.showShareActivity(msg: "Join group", image: nil, url: url.absoluteString, sourceRect: nil)
        })
    }
    
}
