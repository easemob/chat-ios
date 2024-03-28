//
//  NotificationSettingViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/12.
//

import UIKit
import EaseChatUIKit

final class NotificationSettingViewController: UIViewController {
    
    private lazy var navigation: EaseChatNavigationBar = {
        EaseChatNavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: NavigationHeight),textAlignment: .left,rightTitle: "Confirm".chat.localize)
    }()
    
    private lazy var settingName: UILabel = {
        UILabel(frame: CGRect(x: 16, y: self.navigation.frame.maxY+16, width: (self.view.frame.width-32)/2.0, height: 22)).font(UIFont.theme.labelLarge).text("Offline Message Push".localized())
    }()
    
    private lazy var settingSwitch: UISwitch = {
        UISwitch(frame: CGRect(x: self.view.frame.width-63, y: self.navigation.frame.maxY+11.5, width: 51, height: 31))
    }()
    
    private lazy var separatorLine: UIView = {
        UIView(frame: CGRect(x: 16, y: self.settingName.frame.maxY+16, width: self.view.frame.width-16, height: 0.5))
    }()
    
    private lazy var alert: UILabel = {
        UILabel(frame: CGRect(x: 16, y: self.settingName.frame.maxY+20, width: self.view.frame.width-32, height: 18)).font(UIFont.theme.bodyMedium).text("Notification Alert".localized())
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.navigation,self.settingName,self.settingSwitch,self.separatorLine,self.alert])
        self.settingSwitch.addTarget(self, action: #selector(valueChanged(sender:)), for: .touchUpInside)
        self.navigation.clickClosure = { [weak self] _,_ in
            self?.navigationController?.popViewController(animated: true)
        }
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.fetchSilentMode()
    }
    
    private func fetchSilentMode() {
        ChatClient.shared().pushManager?.getSilentModeForAll(completion: { [weak self] result, error in
            guard let `self` = self else { return }
            if error == nil {
                if let remind = result?.remindType {
                    self.settingSwitch.isOn = remind == .mentionOnly ? true:false
                }
            } else {
                consoleLogInfo("error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }

    @objc private func valueChanged(sender: UISwitch) {
        let params = SilentModeParam()
        params.remindType = sender.isOn ? .mentionOnly:.all
        ChatClient.shared().pushManager?.setSilentModeForAll(params, completion: { [weak self] result, error in
            if error != nil {
                self?.settingSwitch.isOn = false
                consoleLogInfo("Set notification error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
}

extension NotificationSettingViewController: ThemeSwitchProtocol {
    func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.settingName.textColor = style == .light ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.settingSwitch.onTintColor = style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
        self.separatorLine.backgroundColor(style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor9)
        self.alert.textColor(style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5)
    }
}