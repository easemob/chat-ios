//
//  MineContactsViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/6/7.
//

import UIKit
import EaseChatUIKit

final class MineContactsViewController: ContactViewController {
    
    private lazy var limitCount: UILabel = {
        UILabel(frame: CGRect(x: 0, y: 13, width: 50, height: 22)).font(UIFont.theme.bodyLarge).text("0/20")
    }()
    
    private var limited = false
    
    private var customStatus = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.listenToUserStatus()
        self.showUserStatus()
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
            let state = PresenceManager.fetchStatus(presence: presence)
            switch state {
            case .online:
                self.navigation.userState = .online
            case .offline:
                self.navigation.userState = .offline
            case .busy:
                self.navigation.status.image = nil
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.errorColor5:UIColor.theme.errorColor6
            case .away:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.away] as? UIImage)
            case .doNotDisturb:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.doNotDisturb] as? UIImage)
            case .custom:
                self.navigation.status.backgroundColor = Theme.style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
                self.navigation.status.image(PresenceManager.presenceImagesMap[.custom] as? UIImage)
            }
            
        }
        
    }
    
    override func navigationClick(type: EaseChatNavigationBarClickEvent, indexPath: IndexPath?) {
        switch type {
        case .back: self.pop()
        case .rightTitle: self.confirmAction()
        case .rightItems: self.rightActions(indexPath: indexPath ?? IndexPath())
        case .avatar: self.showOnlineStatusDialog()
        default:
            break
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
        self.limitCount.text = "0/20"
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
            }
        }
    }

}


extension MineContactsViewController: UITextFieldDelegate {
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
