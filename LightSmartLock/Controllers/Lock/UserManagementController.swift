//
//  UserManagementController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/12/6.
//  Copyright © 2019 mugua. All rights reserved.
//

import MJRefresh
import UIKit
import PKHUD
import Kingfisher

class UserManagementController: UITableViewController, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.navigationBackground.value
    }
    
    let vm = UserManagementViewModel()
    var dataSource: [UserMemberListModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "用户管理"
        setupUI()
        setupTableviewRefresh()
        bind()
    }
    
    func setupTableviewRefresh() {
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {[weak self] in
            self?.vm.refresh()
        })
        
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: {[weak self] in
            self?.vm.loadMore()
        })
        footer.setTitle("", for: .idle)
        tableView.mj_footer = footer
    }
    
    func bind() {
        vm.refreshStaus.subscribe(onNext: {[weak self] (status) in
            switch status {
            case .endFooterRefresh:
                self?.tableView.mj_footer?.endRefreshing()
            case .endHeaderRefresh:
                self?.tableView.mj_header?.endRefreshing()
                self?.tableView.mj_footer?.resetNoMoreData()
            case .noMoreData:
                self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
            case .none:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[weak self] in
                    self?.tableView.mj_header?.beginRefreshing()
                }
            }
        }).disposed(by: rx.disposeBag)
        
        vm.list.subscribe(onNext: {[weak self] (list) in
            self?.dataSource = list
            self?.tableView.reloadData()
        }, onError: { (error) in
            PKHUD.sharedHUD.rx.showError(error)
        }).disposed(by: rx.disposeBag)
    }
    
    func setupUI() {
        self.clearsSelectionOnViewWillAppear = true
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 80.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 8
        default:
            return 24
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserManagementCell", for: indexPath) as! UserManagementCell
        let data = dataSource[indexPath.row]
        
        cell.nickname.text = data.customerNickName
        cell.role.text = data.relationType?.description
        if let pic = data.headPic?.encodeUrl() {
            cell.avatar.kf.setImage(with: URL(string: pic))
        }
        cell.synchronizedStart(data.userCode.isNilOrEmpty)
        return cell
    }
}

class UserManagementCell: UITableViewCell {
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var role: UILabel!
    @IBOutlet weak var sysIcon: UIImageView!
    @IBOutlet weak var synLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        synLabel.isHidden = true
        sysIcon.isHidden = true
    }
    
    func synchronizedStart(_ start: Bool) {
        if start {
            synLabel.isHidden = false
            sysIcon.isHidden = false
            let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.toValue = Double.pi * 2
            rotation.duration = 3
            rotation.isCumulative = true
            rotation.repeatCount = Float.greatestFiniteMagnitude
            sysIcon.layer.add(rotation, forKey: "rotationAnimation")
        } else {
            synLabel.isHidden = true
            sysIcon.isHidden = true
            sysIcon.layer.removeAnimation(forKey: "rotationAnimation")
            self.accessoryType = .disclosureIndicator
        }
    }
}