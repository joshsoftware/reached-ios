//
//  ProfileViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 01/06/21.
//

import UIKit
import SVProgressHUD

class ProfileViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nameLabel: UILabel!
    var groupId: String = ""
    var addressList = [Place]()
    var member = Members()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        nameLabel.text = member.name
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            SVProgressHUD.show()
            DatabaseManager.shared.fetchAddressFor(userWith: userId, groupId: self.groupId) { (response) in
                SVProgressHUD.dismiss()
                for address in response?.allValues ?? [Any]() {
                    if let data = address as? NSDictionary {
                        var place = Place()
                        place.lat = data["lat"] as? Double
                        place.long = data["long"] as? Double
                        place.address = data["address"] as? String
                        place.name = data["name"] as? String
                        place.radius = data["radius"] as? Double
                        self.addressList.append(place)
                    }
                }
                self.collectionView.reloadData()
            }
        }
        // Do any additional setup after loading the view.
    }

     private func setUpCollectionView() {
         collectionView.delegate = self
         collectionView.dataSource = self
         collectionView.register(UINib(nibName: "AddressCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AddressCollectionViewCell")
         collectionView.reloadData()
     }
    
    @IBAction func addAddressBtnAction(_ sender: Any) {
        if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SearchAddressViewController") as? SearchAddressViewController {
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
        return cell ?? UICollectionViewCell()
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height * 0.8, height: collectionView.frame.height)
    }
}
