//
//  HomeViewController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import UIKit
import Lottie
import PKHUD
import RxSwift
import RxCocoa
import Then

class HomeViewController: UIViewController, NavigationSettingStyle {
    
    var backgroundColor: UIColor? {
        return ColorClassification.navigationBackground.value
    }
    
    @IBOutlet weak var noLockView: UIView!
    
    let vm: HomeViewModeling = HomeViewModel()
    
    let tableView: UITableView = UITableView(frame: .zero, style: .plain).then {
        $0.tableFooterView = UIView(frame: .zero)
        $0.register(UINib(nibName: "AnimationHeaderView", bundle: nil), forCellReuseIdentifier: "AnimationHeaderView")
        $0.register(UINib(nibName: "HomeControlCell", bundle: nil), forCellReuseIdentifier: "HomeControlCell")
        $0.register(UINib(nibName: "HomeUnlockRecordHeader", bundle: nil), forCellReuseIdentifier: "HomeUnlockRecordHeader")
        $0.register(UINib(nibName: "UnlockRecordCell", bundle: nil), forCellReuseIdentifier: "UnlockRecordCell")
    }
    
    var dataSource: [UnlockRecordModel] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: .animationRestart, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "门锁助手"
        
        bind()
        setupUI()
        setupRightNavigationItems()
    }
    
    func setupUI() {
        noLockView.alpha = 0
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorClassification.tableViewBackground.value
        view.backgroundColor = ColorClassification.viewBackground.value
    }
    
    func setupRightNavigationItems() {
        let fix = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fix.width = 8
        let fixTwo = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixTwo.width = 16
        
        let moreButton = UIButton(type: .custom)
        moreButton.setImage(UIImage(named: "home_more_item"), for: UIControl.State())
        moreButton.sizeToFit()
        let moreItem = UIBarButtonItem(customView: moreButton)
        
        let notiButton = UIButton(type: .custom)
        notiButton.setImage(UIImage(named: "home_noti_item"), for: UIControl.State())
        notiButton.sizeToFit()
        
        let notiItem = UIBarButtonItem(customView: notiButton)
        self.navigationItem.rightBarButtonItems = [fix, moreItem, fixTwo, notiItem]
    }
    
    func bind() {
        vm.isInstallLock.do(onNext: {[unowned self] (install) in
            self.hasLock(has: install)
        }).flatMapLatest {[unowned self] (_) in
            return self.vm.userInScene
        }.flatMapLatest {[unowned self] (userInScene) -> Observable<SmartLockInfoModel> in
            LSLUser.current().userInScene = userInScene
            return self.vm.lockInfo
        }.flatMapLatest {[unowned self] (lockInfo) -> Observable<IOTLockInfoModel> in
            LSLUser.current().lockInfo = lockInfo
            return self.vm.lockIOTInfo
        }.flatMapLatest {[unowned self] (IOTLockInfo) -> Observable<[UnlockRecordModel]> in
            LSLUser.current().lockIOTInfo = IOTLockInfo
            return self.vm.unlockRecord
        }.subscribe(onNext: {[unowned self] (list) in
            self.dataSource = list
            self.tableView.reloadData()
            }, onError: { (error) in
                PKHUD.sharedHUD.rx.showError(error)
        }).disposed(by: rx.disposeBag)
        
    }
    
    private func hasLock(has: Bool) {
        if has {
            noLockView.alpha = 0
            self.tabBarController?.tabBar.isHidden = false
            self.extendedLayoutIncludesOpaqueBars = false
            self.view.bringSubviewToFront(tableView)
        } else {
            noLockView.alpha = 1
            self.tabBarController?.tabBar.isHidden = true
            self.extendedLayoutIncludesOpaqueBars = true
            self.view.sendSubviewToBack(tableView)
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 2:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnlockRecordCell", for: indexPath) as! UnlockRecordCell
            let data = dataSource[indexPath.row]
            cell.bind(data)
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
        case 1:
            return 0
        case 2:
            return dataSource.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 0 {
            let header = tableView.dequeueReusableCell(withIdentifier: "AnimationHeaderView") as! AnimationHeaderView
            
            header.bind(LSLUser.current().lockIOTInfo)
            return header
        }
        
        if section == 1 {
            let header = tableView.dequeueReusableCell(withIdentifier: "HomeControlCell") as! HomeControlCell
            return header
        }
        
        if section == 2 {
            let header = tableView.dequeueReusableCell(withIdentifier: "HomeUnlockRecordHeader") as! HomeUnlockRecordHeader
            header.checkMoreButton.rx.tap.subscribe(onNext: {[weak self] (_) in
                
                guard let userCode = LSLUser.current().userInScene?.userCode else {
                    HUD.flash(.label("无法获取user code, 请稍后"), delay: 2)
                    return
                }
                let recordVC = RecordUnlockController(userCode: userCode)
                self?.navigationController?.pushViewController(recordVC, animated: true)
                
            }).disposed(by: header.disposeBag)
            return header
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 280.0
        }
        if section == 1 {
            return 80.0
        }
        
        if section == 2 {
            return 40.0
        }
        
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2:
            return 64.0
        default:
            return CGFloat.leastNormalMagnitude
        }
    }
}
