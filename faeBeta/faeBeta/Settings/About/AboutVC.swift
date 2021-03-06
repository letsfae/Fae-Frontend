//
//  SetAboutViewController.swift
//  FaeSettings
//
//  Created by 子不语 on 2017/9/11.
//  Copyright © 2017年 子不语. All rights reserved.
//

import UIKit

class SetAboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - Properties
    private var uiviewNavBar: FaeNavBar!
    private var arrAboutString: [String] = ["Company", "About Fae Map", "Fae Map Website", "Terms of Service", "Privacy Policy"]
    private var tblAbout: UITableView!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        uiviewNavBar = FaeNavBar(frame:.zero)
        view.addSubview(uiviewNavBar)
        self.navigationController?.isNavigationBarHidden = true
        uiviewNavBar.lblTitle.text = "About"
        uiviewNavBar.leftBtn.addTarget(self, action: #selector(actionGoBack(_:)), for: .touchUpInside)
        uiviewNavBar.loadBtnConstraints()
        uiviewNavBar.rightBtn.setImage(nil, for: .normal)
        
        tblAbout = UITableView(frame: CGRect(x: 0, y: 65 + device_offset_top, width: screenWidth, height: screenHeight - 65 - device_offset_top))
        view.addSubview(tblAbout)
        tblAbout.separatorStyle = .none
        tblAbout.delegate = self
        tblAbout.dataSource = self
        tblAbout.register(GeneralTitleCell.self, forCellReuseIdentifier: "GeneralTitleCell")
        tblAbout.estimatedRowHeight = 60
    }
    
    // MARK: - Button action
    @objc private func actionGoBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrAboutString.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralTitleCell", for: indexPath as IndexPath) as! GeneralTitleCell
        cell.switchIcon.isHidden = true
        cell.lblDes.isHidden = true
        cell.imgView.isHidden = false
        cell.setContraintsForDes(desp: false)
        cell.lblName.text = arrAboutString[indexPath.row]
        cell.topGrayLine.isHidden = true
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(SetFaeInc(), animated: true)
        case 1:
            navigationController?.pushViewController(SetFaeMap(), animated: true)
        case 2:
            navigationController?.pushViewController(SetWebViewController(), animated: true)
        case 3:
            let vc = TermsOfServiceViewController()
            vc.boolPush = true
            navigationController?.pushViewController(vc, animated: true)
        case 4:
            let vc = PrivacyPolicyViewController()
            vc.boolPush = true
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
}
