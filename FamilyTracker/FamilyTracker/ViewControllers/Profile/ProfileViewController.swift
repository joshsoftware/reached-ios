//
//  ProfileViewController.swift
//  FamilyTracker
//
//  Created by Mahesh on 01/06/21.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()

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
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddressCollectionViewCell", for: indexPath) as? AddressCollectionViewCell
        return cell ?? UICollectionViewCell()
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height * 0.8, height: collectionView.frame.height)
    }
}
