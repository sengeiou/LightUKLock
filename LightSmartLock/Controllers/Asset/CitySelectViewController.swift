//
//  CitySelectViewController.swift
//  LightSmartLock
//
//  Created by changjun on 2020/5/15.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import HandyJSON
import Reusable

struct CityModel: HandyJSON {
    var code: Int!
    var lat: Int!
    var lng: Int!
    var level: Int!
    var mergerName: String!
    var name: String!
    var parentCode: Int!
    var pinYin: String!
    var shortName: String!
    
    var isSelected = false
}


class HotCityCell: UICollectionViewCell, NibReusable {
    
    @IBOutlet weak var configBtn: ConfigButton!
    
    var model: CityModel! {
        didSet {
            configBtn.setTitle(model.shortName, for: .normal)
            configBtn.isSelected = model.isSelected
        }
    }
}

class CitySelectViewController: UIViewController {
    
    @IBOutlet weak var hotCityCollectionView: UICollectionView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    let hotCityRelay = BehaviorRelay<[CityModel]>.init(value: [])
    
    var indeTitle: [String] = []
    var dataSrouce: [[CityModel]] = []
    var didSelectCitt: ((CityModel)->Void)?
    
    static let hotCities = [
        "北京","上海","广州","深圳",
        "成都","重庆","杭州","武汉",
        "南京","西安","长沙","厦门"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        hotCityRelay
            .bind(to: hotCityCollectionView.rx.items(cellIdentifier: "HotCityCell", cellType: HotCityCell.self)) { (row, element, cell) in
                cell.model = element
        }
        .disposed(by: rx.disposeBag)
        
        hotCityCollectionView.rx.modelSelected(CityModel.self)
            .subscribe(onNext: { (model) in
                self.select(city: model)
            })
            .disposed(by: rx.disposeBag)
        
        loadCityJsonFile()
    }
    
    func loadCityJsonFile() {
        
        self.indicatorView.startAnimating()
        DispatchQueue.global().async {[weak self] in
            let file = Bundle.main.url(forResource: "zh_city", withExtension: "json")
            let data = try! Data(contentsOf: file!)
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            
            let object = json as? [[String: Any]]
            let tempCities = [CityModel].deserialize(from: object)
            let tempCitiesMap = tempCities?.compactMap{ $0 }
            guard let allEntity = tempCitiesMap else { return }
            let cityArray = allEntity.filter { $0.level == 2 }
            
            let hotCityArray = cityArray.filter { Self.hotCities.contains($0.shortName)}
            
            self?.hotCityRelay.accept(hotCityArray)
            
            let result = Dictionary(grouping: cityArray, by: { String($0.pinYin.first ?? "Z") }).sorted(by: { (a, b) -> Bool in
                return a.key < b.key
            })
            
            DispatchQueue.main.async {[weak self] in
                for (key, value) in result {
                    self?.indeTitle.append(key)
                    self?.dataSrouce.append(value)
                    self?.indicatorView.stopAnimating()
                }
                self?.tableView.reloadData()
            }
        }
    }
}

extension CitySelectViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return indeTitle.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = dataSrouce[section]
        return group.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        let name = dataSrouce[indexPath.section][indexPath.row].name
        cell.textLabel?.text = name
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return indeTitle[section]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return indeTitle
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cityModel = dataSrouce[indexPath.section][indexPath.row]
        select(city: cityModel)
    }
    
    func select(city: CityModel) {
        didSelectCitt?(city)
        navigationController?.popViewController(animated: true)
    }
    
}
