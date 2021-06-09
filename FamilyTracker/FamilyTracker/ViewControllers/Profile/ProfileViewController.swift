//
//  ProfileViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 01/06/21.
//

import UIKit
import SDWebImage

class ProfileViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    var groupId: String = ""
    var addressList = [Place]()
    var member = Members()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        nameLabel.text = member.name
        if let url = URL(string: member.profileUrl ?? "") {
            SDWebImageDownloader.shared.downloadImage(with: url) { (image, _, _, _) in
                self.profileImageView.image = image
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchAddressHandler), name: NSNotification.Name(rawValue: "fetchAddressNotification"), object: nil)

        fetchAddress()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.cornerRadius = profileImageView.frame.height / 2
    }

     private func setUpCollectionView() {
         collectionView.delegate = self
         collectionView.dataSource = self
         collectionView.register(UINib(nibName: "AddressCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AddressCollectionViewCell")
         collectionView.reloadData()
     }
    
    @objc func fetchAddressHandler() {
        fetchAddress()
    }
    
    func fetchAddress() {
        self.addressList.removeAll()
        ProgressHUD.sharedInstance.show()
        DatabaseManager.shared.fetchAddressFor(userWith: member.id ?? "", groupId: self.groupId) { (response) in
            ProgressHUD.sharedInstance.hide()
            if let address = response {
                for (key, value) in address {
                    if let data = value as? NSDictionary {
                        var place = Place()
                        place.id = key as? String
                        place.lat = data["lat"] as? Double
                        place.long = data["long"] as? Double
                        place.address = data["address"] as? String
                        place.name = data["name"] as? String
                        place.radius = data["radius"] as? Double
                        self.addressList.append(place)
                    }
                }
            }
            self.collectionView.reloadData()
        }
    }
    
    @IBAction func addAddressBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SearchAddressViewController") as? SearchAddressViewController {
            vc.userId = member.id ?? ""
            vc.groupId = self.groupId
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func loacateBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Dashboard", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController {
            vc.groupId = groupId
            vc.showAllGroupMembers = false
            vc.memberList.append(member)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ProfileViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.addressList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressCollectionViewCell", for: indexPath) as? AddressCollectionViewCell
        let address = self.addressList[indexPath.row]
        cell?.setupCell(place: address)
        cell?.onClickRemoveAddressHandler = {
            DatabaseManager.shared.removeAddresFor(userWith: self.member.id ?? "", groupId: self.groupId, addressId: address.id ?? "") { (response, error) in
                if error != nil {
                    print(error ?? "")
                } else {
                    print(response ?? "")
                    self.fetchAddress()
                }
            }
        }
        return cell ?? UICollectionViewCell()
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height * 0.8, height: collectionView.frame.height)
    }
}
