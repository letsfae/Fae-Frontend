//
//  SetInfoViewController2.swift
//  FaeSettings
//
//  Created by 子不语 on 2017/9/24.
//  Copyright © 2017年 子不语. All rights reserved.
//

import UIKit

class SetInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GeneralTitleCellDelegate {
    // MARK: - Properties
    private var tblInfo: UITableView!
    private var uiviewNavBar: FaeNavBar!
    private var arrTitle: [String] = ["Edit NameCard", "Hide NameCard Options", "Disable Gender", "Disable Age"]
    private var arrDetail: [String] = ["Preview and Edit Information on your NameCard.", "Hide the bottom NameCard Options for you and other users. Contacts are excluded.", "Gender will be hidden for you and all other users. You will no longer be able to use Gender Filters.", "Age will be hidden for you and all other users. You will no longer be able to use Age Filters."]
    private var activityIndicator: UIActivityIndicatorView!
    var enterMode: SetInfoEnterMode!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.isNavigationBarHidden = true
        loadNavBar()
        loadTableView()
        loadActivityIndicator()
    }
    
    // MARK: - Set up
    private func loadActivityIndicator() {
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor._2499090()
        view.addSubview(activityIndicator)
        view.bringSubview(toFront: activityIndicator)
    }
    
    private func loadNavBar() {
        uiviewNavBar = FaeNavBar(frame: .zero)
        view.addSubview(uiviewNavBar)
        uiviewNavBar.lblTitle.text = "My Information"
        uiviewNavBar.leftBtn.addTarget(self, action: #selector(actionGoBack(_:)), for: .touchUpInside)
        uiviewNavBar.loadBtnConstraints()
        uiviewNavBar.rightBtn.setImage(nil, for: .normal)
    }
    
    private func loadTableView() {
        tblInfo = UITableView(frame: CGRect(x: 0, y: 65 + device_offset_top, width: screenWidth, height: screenHeight - 65 - device_offset_top))
        view.addSubview(tblInfo)
        tblInfo.separatorStyle = .none
        tblInfo.delegate = self
        tblInfo.dataSource = self
        tblInfo.register(GeneralTitleCell.self, forCellReuseIdentifier: "GeneralTitleCell")
        tblInfo.estimatedRowHeight = 110
        tblInfo.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK:- Button action
    @objc private func actionGoBack(_ sender: UIButton) {
        if enterMode == .nameCard {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - GeneralTitleCellDelegate
    func startUpdating() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    func stopUpdating() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralTitleCell", for: indexPath as IndexPath) as! GeneralTitleCell
        cell.lblName.isHidden = false
        cell.lblDes.isHidden = false
        cell.setContraintsForDes()
        cell.delegate = self
        if indexPath.section == 0 {
            cell.switchIcon.isHidden = true
            cell.imgView.isHidden = false
            cell.topGrayLine.isHidden = true
        } else {
            cell.switchIcon.isHidden = false
            cell.switchIcon.tag = indexPath.section + 100
            if indexPath.section == 1 {
                cell.switchIcon.setOn(!Key.shared.showNameCardOption, animated: false)
            } else if indexPath.section == 2 {
                cell.switchIcon.setOn(Key.shared.disableGender, animated: false)
            } else if indexPath.section == 3 {
                cell.switchIcon.setOn(Key.shared.disableAge, animated: false)
            }
            cell.imgView.isHidden = true
            cell.topGrayLine.isHidden = false
        }
        cell.lblDes.text = arrDetail[indexPath.section]
        cell.lblName.text = arrTitle[indexPath.section]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let vc = SetInfoNamecard()
            vc.enterMode = enterMode
            if enterMode == .nameCard {
                present(vc, animated: true)
            } else {
                navigationController?.pushViewController(vc, animated: true)
            }
        default: break
        }
    }
}
