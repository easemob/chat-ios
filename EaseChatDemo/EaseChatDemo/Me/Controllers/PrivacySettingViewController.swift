//
//  PrivacySettingViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/6/4.
//

import UIKit
import EaseChatUIKit

final class PrivacySettingViewController: UIViewController {
    
    
    private lazy var jsons: [Dictionary<String,Any>] = {
        Appearance.contact.enableBlock ? [
            ["title":"block_list".localized(),"detail":"","withSwitch": false,"switchValue":false]
        ]:[
        ]
    }()
    
    private lazy var datas: [DetailInfo] = {
        self.jsons.map {
            let info = DetailInfo()
            info.setValuesForKeys($0)
            return info
        }
    }()
    
    private lazy var navigation: EaseChatNavigationBar = {
        EaseChatNavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: NavigationHeight), textAlignment: .left, rightTitle: nil)
    }()
    
    private lazy var featureList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: NavigationHeight, width: self.view.frame.width, height: self.view.frame.height), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(54).backgroundColor(.clear).separatorStyle(.none)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.navigation,self.featureList])
        self.navigation.title = "Privacy".localized()
        self.navigation.clickClosure = { [weak self] _,_ in
            self?.navigationController?.popViewController(animated: true)
        }
        // Do any additional setup after loading the view.
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
        

}

extension PrivacySettingViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "PrivacySettingCell") as? DetailInfoListCell
        if cell == nil {
            cell = DetailInfoListCell(style: .value2, reuseIdentifier: "PrivacySettingCell")
        }
        let info = self.jsons[indexPath.row]
        let withSwitch = info["withSwitch"] as? Bool ?? false
        let switchValue = info["switchValue"] as? Bool ?? false
        if let info = self.datas[safe: indexPath.row] {
            cell?.refresh(info: info)
        }
        cell?.valueChanged = { [weak self] in
            self?.switchChanged(isOn: $0, indexPath: $1)
        }
        cell?.accessoryType = withSwitch ? .none:.disclosureIndicator
        return cell ?? UITableViewCell()
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = BlockContactsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func switchChanged(isOn: Bool, indexPath: IndexPath) {
        if let title = self.datas[safe: indexPath.row]?.title {
//            switch title {
//            case "typing_indicator".localized():
//                Appearance.chat.enableTyping = isOn
//                self.typing = isOn
//            default:
//                break
//            }
            
        }
    }
    
}

extension PrivacySettingViewController: ThemeSwitchProtocol {
    func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
    }
}
