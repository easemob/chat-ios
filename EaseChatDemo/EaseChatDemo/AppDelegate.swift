//
//  AppDelegate.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit
import HyphenateChat
import UserNotifications
import SwiftFFDBHotFix

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    @UserDefault("EaseChatDemoServerConfig", defaultValue: Dictionary<String,String>()) private var serverConfig
    
    @UserDefault("EaseChatDemoPreferencesTheme", defaultValue: 0) var theme: UInt
    
    @UserDefault("EaseMobChatMessageTranslation", defaultValue: true) var enableTranslation: Bool
    
    @UserDefault("EaseMobChatMessageReaction", defaultValue: true) var messageReaction: Bool
    
    @UserDefault("EaseMobChatCreateMessageThread", defaultValue: true) var messageThread: Bool
    
    @UserDefault("EaseChatDemoPreferencesBlock", defaultValue: true) var block: Bool
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.setupEaseChatUIKit()
        self.setupEaseChatUIKitConfig()
        self.registerRemoteNotification()
        return true
    }
    
    private func setupEaseChatUIKit() {
        var appKey = AppKey
        if let applicationKey = self.serverConfig["application"],let debugMode = self.serverConfig["debug_mode"],debugMode == "1" {
            appKey = applicationKey
        }
        let options = ChatOptions(appkey: appKey)
        options.includeSendMessageInMessageListener = true
        options.isAutoLogin = true
        options.enableConsoleLog = true
        options.usingHttpsOnly = true
        options.deleteMessagesOnLeaveGroup = false
        options.enableDeliveryAck = true
        options.enableRequireReadAck = true
        //Simulator can't use APNS, so we need to judge whether it is a real machine.
        #if DEBUG
        options.apnsCertName = "EaseIM_APNS_Developer"
        #else
        options.apnsCertName = "EaseIM_APNS_Product"
        #endif
        
        if let debugMode = self.serverConfig["debug_mode"],debugMode == "1",let customServer = self.serverConfig["use_custom_server"], customServer == "1" {
            options.setValue(false, forKey: "enableDnsConfig")
            options.setValue(true, forKey: "usingHttpsOnly")
            //Set the chat server and rest server address.Using private deploy.
            if let chatServer = self.serverConfig["chat_server_ip"] {
                options.setValue(chatServer, forKey: "chatServer")
            }
        
            if let chatPort = Int(self.serverConfig["chat_server_port"] ?? "6717") {
                options.setValue(chatPort, forKey: "chatPort")
            }

            if let restAddress = self.serverConfig["rest_server_address"] {
                options.setValue(restAddress, forKey: "restServer")
            }
        }
        //Set up EaseChatUIKit
        _ = EaseChatUIKitClient.shared.setup(option: options)
        EaseChatUIKitClient.shared.registerUserStateListener(self)
    }
    
    private func setupEaseChatUIKitConfig() {
        //Set the theme of the chat demo UI.
        if self.theme == 0 {
            Appearance.avatarRadius = .extraSmall
            Appearance.chat.inputBarCorner = .extraSmall
            Appearance.alertStyle = .small
            Appearance.chat.bubbleStyle = .withArrow
        } else {
            Appearance.avatarRadius = .large
            Appearance.chat.inputBarCorner = .large
            Appearance.alertStyle = .large
            Appearance.chat.bubbleStyle = .withMultiCorner
        }
        Appearance.hiddenPresence = false
        Appearance.chat.enableTyping = true
        Appearance.contact.enableBlock = self.block
        //Enable message translation
        Appearance.chat.enableTranslation = self.enableTranslation
        if Appearance.chat.enableTranslation {
            let preferredLanguage = NSLocale.preferredLanguages[0]
            if preferredLanguage.starts(with: "zh-Hans") || preferredLanguage.starts(with: "zh-Hant") {
                Appearance.chat.targetLanguage = .Chinese
            } else {
                Appearance.chat.targetLanguage = .English
            }
        }
        //Whether show message topic or not.
        if self.messageThread {
            Appearance.chat.contentStyle.append(.withMessageThread)
        }
        //Whether show message reaction or not.
        if self.messageReaction {
            Appearance.chat.contentStyle.append(.withMessageReaction)
        }
        //Notice: - Feature identify can't changed, it's used to identify feature action.
        
        //Register custom components
        ComponentsRegister.shared.ConversationsController = MineConversationsController.self
        ComponentsRegister.shared.ContactsController = MineContactsViewController.self
        ComponentsRegister.shared.MessageViewController = MineMessageListViewController.self
        ComponentsRegister.shared.ContactInfoController = MineContactDetailViewController.self
        ComponentsRegister.shared.GroupInfoController = MineGroupDetailViewController.self
    }
    
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }

    private func registerRemoteNotification() {
        //Simulator can't use APNS, so we need to judge whether it is a real machine.
        #if !targetEnvironment(simulator)
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        EMLocalNotificationManager.shared().launch(with: self)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Handle granted and error here
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        #endif
    }

}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ChatClient.shared().registerForRemoteNotifications(withDeviceToken: deviceToken) { error in
            if error != nil {
                consoleLogInfo("Register for remote notification error:\(error?.errorDescription ?? "")", type: .error)
            }
        }
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        DialogManager.shared.showAlert(title: "Register notification failed", content: error.localizedDescription, showCancel: true, showConfirm: true) { _ in
            
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ChatClient.shared().application(application, didReceiveRemoteNotification: userInfo)
    }
    
    
}


extension AppDelegate: EMLocalNotificationDelegate {
    func emGetNotificationMessage(_ notification: UNNotification, state: EMNotificationState) {

        if notification.request.trigger is UNPushNotificationTrigger {
            //apns
            DialogManager.shared.showAlert(title: state == .willPresentNotification ? "Push Arrive":"Push Click", content: notification.request.content.title, showCancel: false, showConfirm: true) { _ in
                
            }
        } else {
            //local notification
            if let userInfo = notification.request.content.userInfo as? [String: Any] {
                DialogManager.shared.showAlert(title: state == .willPresentNotification ? "Local Arrive":"Local Click", content: notification.request.content.title, showCancel: false, showConfirm: true) { _ in
                    
                }
            }
        }
        if state == .didReceiveNotificationResponse {
            //click notification enter app
        } else {
            //notification will dispaly
        }
    }
}

//MARK: - UserStateChangedListener
extension AppDelegate: UserStateChangedListener {
    
    private func logoutUser() {
        EaseChatUIKitClient.shared.logout(unbindNotificationDeviceToken: true) { error in
            if error != nil {
                consoleLogInfo("Logout failed:\(error?.errorDescription ?? "")", type: .error)
            }
        }
    }
    
    func onUserTokenDidExpired() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
    }
    
    func onUserLoginOtherDevice(device: String) {
        self.logoutUser()
        NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
    }
    
    func onUserTokenWillExpired() {
        //Notice: - If you want to refresh token, you need to implement the logic in this method.
//        EaseChatUIKitClient.shared.refreshToken(token: token)
    }
    
    func onSocketConnectionStateChanged(state: EaseChatUIKit.ConnectionState) {
        //Socket state monitor network
    }
    
    func userAccountDidRemoved() {
        self.logoutUser()
        NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
    }
    
    func userDidForbidden() {
        self.logoutUser()
        NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
    }
    
    func userAccountDidForcedToLogout(error: EaseChatUIKit.ChatError?) {
        self.logoutUser()
        NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
    }
    
    func onUserAutoLoginCompletion(error: EaseChatUIKit.ChatError?) {
        if error != nil {
            NotificationCenter.default.post(name: Notification.Name(rawValue: backLoginPage), object: nil)
        } else {
            ChatClient.shared().pushManager?.syncSilentModeConversations(fromServerCompletion: { error in
                
            })
            if let groups = ChatClient.shared().groupManager?.getJoinedGroups() {
                var profiles = [EaseChatProfile]()
                for group in groups {
                    let profile = EaseChatProfile()
                    profile.id = group.groupId
                    profile.nickname = group.groupName
                    profile.avatarURL = group.settings.ext
                    profiles.append(profile)
                }
                EaseChatUIKitContext.shared?.updateCaches(type: .group, profiles: profiles)
            }
            if let users = EaseChatUIKitContext.shared?.userCache {
                for user in users.values {
                    EaseChatUIKitContext.shared?.userCache?[user.id]?.remark = ChatClient.shared().contactManager?.getContact(user.id)?.remark ?? ""
                }
            }
            NotificationCenter.default.post(name: Notification.Name(loginSuccessfulSwitchMainPage), object: nil)
        }
    }
    
}
