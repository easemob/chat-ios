//
//  MeViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit
import SwiftFFDBHotFix

final class MeViewController: UIViewController {
    
    private var menusData: [[String:Any]] {
        [
            ["sectionTitle":"Setting".localized(),"sectionData":[["title":"online_status".localized(),"icon":"online_status","detail":PresenceManager.shared.currentUserStatus],["title":"Personal info".localized(),"icon":"userinfo"],["title":"General".localized(),"icon":"general"],["title":"Notification".localized(),"icon":"notification"],["title":"Privacy".localized(),"icon":"privacy"],["title":"About".localized(),"icon":"about"]]],
            ["sectionTitle":"Login".localized(),"sectionData":[["title":"Logout".localized()]]]
        ]
    }
    
    private lazy var header: DetailInfoHeader = {
        DetailInfoHeader(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 204), showMenu: false, placeHolder: Appearance.conversation.singlePlaceHolder)
    }()
    
    private lazy var menuList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: NavigationHeight, width: ScreenWidth, height: ScreenHeight-NavigationHeight-BottomBarHeight-(self.tabBarController?.tabBar.frame.height ?? 49)), style: .plain).backgroundColor(.clear).separatorStyle(.none).tableFooterView(UIView()).tableHeaderView(self.header).dataSource(self).delegate(self).rowHeight(54)
    }()
    
    private lazy var limitCount: UILabel = {
        UILabel(frame: CGRect(x: 0, y: 13, width: 50, height: 22)).font(UIFont.theme.bodyLarge).text("0/20")
    }()
    
    private var limited = false
    
    private var customStatus = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(self.menuList)
        let userId = EaseChatUIKitContext.shared?.currentUserId ?? ""
        var nickName = EaseChatUIKitContext.shared?.currentUser?.nickname ?? ""
        if nickName.isEmpty {
            nickName = userId
        }
        self.fetchUserInfo(userId: userId)
        self.header.nickName.text = nickName
        self.header.detailText = userId
        self.header.avatarURL = EaseChatUIKitContext.shared?.currentUser?.avatarURL ?? ""
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.listenToUserStatus()
        self.showUserStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshProfile), name: NSNotification.Name(rawValue: userAvatarUpdated), object: nil)
    }
    
    private func fetchUserInfo(userId: String) {
        ChatClient.shared().userInfoManager?.fetchUserInfo(byId: [userId], type: [0,1], completion: { [weak self] infoMap, error in
            if let info = infoMap?[userId],error == nil {
                DispatchQueue.main.async {
                    self?.header.nickName.text = info.nickname
                    self?.header.detailText = userId
                    self?.header.avatarURL = info.avatarUrl
                }
                if let profiles = EaseChatProfile.select(where: "id = ?",values: [userId]) as? [EaseChatProfile],let profile = profiles.first(where: { $0.id == userId }) {
                    profile.nickname = info.nickname ?? ""
                    profile.avatarURL = info.avatarUrl ?? ""
                    profile.updateFFDB()
                    EaseChatUIKitContext.shared?.currentUser = profile
                    EaseChatUIKitContext.shared?.userCache?[profile.id] = profile
                } else {
                    let profile = EaseChatProfile()
                    profile.id = userId
                    profile.nickname = info.nickname ?? ""
                    profile.avatarURL = info.avatarUrl ?? ""
                    profile.insert()
                    EaseChatUIKitContext.shared?.currentUser = profile
                    EaseChatUIKitContext.shared?.userCache?[profile.id] = profile
                }
            } else {
                DispatchQueue.main.async {
                    self?.showToast(toast: "fetchUserInfo error:\(error?.errorDescription ?? "")")
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        let userId = EaseChatUIKitContext.shared?.currentUserId ?? ""
        var nickName = EaseChatUIKitContext.shared?.currentUser?.nickname ?? ""
        if nickName.isEmpty {
            nickName = userId
        }
        if self.header.nickName.text != nickName,!nickName.isEmpty {
            self.header.nickName.text = nickName
        }
        if let url = EaseChatUIKitContext.shared?.currentUser?.avatarURL,!url.isEmpty  {
            self.header.avatarURL = url
        }
        self.menuList.reloadData()
    }
    
    @objc private func refreshProfile() {
        self.header.avatarURL = EaseChatUIKitContext.shared?.currentUser?.avatarURL
    }
    
    private func listenToUserStatus() {
        PresenceManager.shared.usersStatusChanged = { [weak self] users in
            if let user = users.first(where: { EaseChatUIKitContext.shared?.currentUserId ?? "" == $0
            }) {
                self?.showUserStatus()
            }
        }
    }
    
    private func showUserStatus() {
        if let presence = PresenceManager.shared.presences[EaseChatUIKitContext.shared?.currentUserId ?? ""] {
            switch PresenceManager.fetchStatus(presence: presence) {
            case .online: self.header.userState = .online
            case .offline: self.header.userState = .offline
            case .busy:
                self.header.status.image = nil
                self.header.status.backgroundColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6            
            case .away:
                self.header.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.header.status.image(PresenceManager.presenceImagesMap[.away] as? UIImage)
            case .doNotDisturb:
                self.header.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.header.status.image(PresenceManager.presenceImagesMap[.doNotDisturb] as? UIImage)
            case .custom:
                self.header.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.header.status.image(PresenceManager.presenceImagesMap[.custom] as? UIImage)
            }
            self.menuList.reloadData()
        }
        
    }

}

extension MeViewController: UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.menusData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (self.menusData[safe:section]?["sectionData"] as? Array<Dictionary<String,Any>>)?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        26
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView {
            UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 26))
            UILabel(frame: CGRect(x: 16, y: 4, width: ScreenWidth-32, height: 18)).font(UIFont.theme.labelMedium).textColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor6).text(self.menusData[section]["sectionTitle"] as? String ?? "").backgroundColor(.clear)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "MeMenuCell") as? MeMenuCell
        if cell == nil {
            cell = MeMenuCell(style: .default, reuseIdentifier: "MeMenuCell")
        }
        
        if let rowDatas = self.menusData[safe:indexPath.section]?["sectionData"] as? Array<Dictionary<String,String>> {
            let title = rowDatas[safe:indexPath.row]?["title"] as? String
            let detail = rowDatas[safe:indexPath.row]?["detail"] as? String
            let imageName = rowDatas[safe:indexPath.row]?["icon"] ?? ""
            cell?.icon.image = UIImage(named: imageName)
            if let rowTitle = title,rowTitle == "Logout".localized() {
                cell?.textLabel?.text = title
                cell?.textLabel?.isHidden = false
                cell?.icon.isHidden = true
                cell?.content.isHidden = true
                cell?.detail.isHidden = true
            } else {
                cell?.content.text = title
                cell?.detail.text = detail
                cell?.icon.isHidden = false
                cell?.textLabel?.isHidden = true
                cell?.content.isHidden = false
                cell?.detail.isHidden = false
                cell?.accessoryType = .disclosureIndicator
                cell?.content.textColor = Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
            }
        }
        
        return cell ?? MeMenuCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let rowDatas = self.menusData[safe:indexPath.section]?["sectionData"] as? Array<Dictionary<String,String>>,let title = rowDatas[safe:indexPath.row]?["title"] as? String {
            switch title {
            case "online_status".localized(): self.showOnlineStatusDialog()
            case "Personal info".localized(): self.viewProfile()
            case "General".localized(): self.viewGeneral()
            case "Notification".localized(): self.viewNotification()
            case "About".localized(): self.viewAbout()
            case "Logout".localized(): self.logout()
            case "Privacy".localized(): self.privacySetting()
            default:
                break
            }
        }
    }
    
    private func viewProfile() {
        let vc = PersonalInfoViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func viewGeneral() {
        let vc = GeneralViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func viewNotification() {
        let vc = NotificationSettingViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func viewAbout() {
        let vc = AboutEasemobController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func privacySetting() {
        let vc = PrivacySettingViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func logout() {
        DialogManager.shared.showAlert(title: "Confirm Logout".localized(), content: "", showCancel: true, showConfirm: true) { _ in
            EaseChatUIKitClient.shared.logout(unbindNotificationDeviceToken: true) { error in
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name(backLoginPage), object: nil, userInfo: nil)
                } else {
                    EaseChatUIKitClient.shared.logout(unbindNotificationDeviceToken: false) { _ in
                        NotificationCenter.default.post(name: Notification.Name(backLoginPage), object: nil, userInfo: nil)
                    }
                    self.showToast(toast: "\(error?.errorDescription ?? "")")
                }
            }
        }
    }
    
    @objc func showOnlineStatusDialog() {
        let actions = [ActionSheetItem(title: "Online".localized(), type: .normal, tag: "online"),
                       ActionSheetItem(title: "Busy".localized(), type: .normal, tag: "busy"),
                       ActionSheetItem(title: "Do Not Disturb".localized(), type: .normal, tag: "disturb"),
                       ActionSheetItem(title: "Away".localized(), type: .normal, tag: "away"),
                       ActionSheetItem(title: "Custom Status".localized().localized(), type: .normal, tag: "custom_status")]
        DialogManager.shared.showActions(actions: actions) { [weak self] in
            self?.publishPresenceState(item: $0)
        }
    }
    
    @objc func publishPresenceState(item: ActionSheetItemProtocol) {
        var status: String?
        switch item.tag {
        case "busy":
            status = "\(PresenceManager.State.busy.rawValue)"
        case "disturb":
            status = "\(PresenceManager.State.doNotDisturb.rawValue)"
        case "away":
            status = "\(PresenceManager.State.away.rawValue)"
        case "custom_status":
            self.showCustomOnlineStatusAlert()
        default:
            break
        }
        PresenceManager.shared.publishPresence(description: status) { [weak self] error in
            if error != nil {
                self?.showToast(toast: "发布状态失败！")
            }
        }
    }
    
    @objc func showCustomOnlineStatusAlert() {
        let size = Appearance.alertContainerConstraintsSize
        let alert = AlertView().background(color: Theme.style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor98).title(title: "Custom Status".localized()).cornerRadius(Appearance.alertStyle == .small ? .extraSmall:.medium).titleColor(color: Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        alert.textField(font: UIFont.theme.bodyLarge).textField(color: Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).textFieldPlaceholder(color: Theme.style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor6).textFieldPlaceholder(placeholder: "Please input".chat.localize).textFieldRadius(cornerRadius: Appearance.alertStyle == .small ? .extraSmall:.medium).textFieldBackground(color: Theme.style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor95).textFieldDelegate(delegate: self).textFieldRightView(rightView: self.limitCount)
        alert.textField.becomeFirstResponder()
        alert.leftButton(color: Theme.style == .dark ? UIColor.theme.neutralColor95:UIColor.theme.neutralColor3).leftButtonBorder(color: Theme.style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor7).leftButton(title: "report_button_click_menu_button_cancel".chat.localize).leftButtonRadius(cornerRadius: Appearance.alertStyle == .small ? .extraSmall:.large)
        alert.rightButtonBackground(color: Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).rightButton(color: UIColor.theme.neutralColor98).rightButtonTapClosure { [weak self] _ in
            guard let `self` = self else { return }
            if self.limited {
                self.showToast(toast: "The length of the custom status should be less than 20 characters".chat.localize)
                return
            } else {
                self.limitCount.text = "0/20"
                PresenceManager.shared.publishPresence(description: self.customStatus) { [weak self] error in
                    if error != nil {
                        self?.showToast(toast: "发布状态失败！")
                    }
                }
            }
        }.rightButton(title: "Confirm".chat.localize).rightButtonRadius(cornerRadius: Appearance.alertStyle == .small ? .extraSmall:.large)
        let alertVC = AlertViewController(custom: alert,size: size, customPosition: true)
        let vc = UIViewController.currentController
        if vc != nil {
            vc?.presentViewController(alertVC)
        }
    }
    
    private func publishCustomStatus() {
        PresenceManager.shared.publishPresence(description: self.customStatus) { [weak self] error in
            if error != nil {
                self?.showToast(toast: "自定义状态设置失败")
            } else {
                self?.menuList.reloadData()
            }
        }
    }
}

extension MeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.customStatus = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if self.customStatus.count > 0 {
            self.limited = self.customStatus.count > 20
            self.limitCount.text = "\(self.customStatus.count)/20"
            if self.customStatus.count > 20 {
                self.limitCount.textColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            } else {
                self.limitCount.textColor = Theme.style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor7
            }
        } else {
            self.limitCount.text = "0/20"
        }
        return true
    }
}


extension MeViewController: ThemeSwitchProtocol {
    
    func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.limitCount.textColor = style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor7
        self.menuList.reloadData()
    }
}

extension FFObject {
    @discardableResult
    public func updateFFDB() -> Bool {
        do {
            var values = [Any]()
            for column in subType.columnsOfSelf() {
                let value = valueNotNullFrom(column)
                values.append(value)
            }
            values.append(valueNotNullFrom("id"))
//            values.append(valueNotNullFrom(subType.primaryKeyColumn()))
            return try FFDBManager.update(subType, set: subType.columnsOfSelf(), where: "id = ?",values:values)
        } catch {
            consoleLogInfo("failed: \(error.localizedDescription)", type: .error)
        }
        return false
    }
}

