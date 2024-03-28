//
//  MainViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit
import EaseCallKit
import SwiftFFDB

final class MainViewController: UITabBarController {
    
    private lazy var chats: ConversationListController = {
        let vc = EaseChatUIKit.ComponentsRegister.shared.ConversationsController.init()
        vc.tabBarItem.tag = 0
        vc.viewModel?.registerEventsListener(listener: self)
        return vc
    }()
    
    private lazy var contacts: ContactViewController = {
        let vc = EaseChatUIKit.ComponentsRegister.shared.ContactsController.init(headerStyle: .contact)
        vc.tabBarItem.tag = 1
        vc.viewModel?.registerEventsListener(self)
        return vc
    }()
    
    private lazy var me: MeViewController = {
        let vc = MeViewController()
        vc.tabBarItem.tag = 2
        return vc
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIApplication.shared.chat.keyWindow != nil {
            tabBar.frame = CGRect(x: 0, y: ScreenHeight-BottomBarHeight-49, width: ScreenWidth, height: BottomBarHeight+49)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.insetsLayoutMarginsFromSafeArea = false
        self.tabBarController?.additionalSafeAreaInsets = .zero
        self.callKitSet()
        self.setupDataProvider()
        self.loadViewControllers()
        // Do any additional setup after loading the view.
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    private func setupDataProvider() {
        //userProfileProvider为用户数据的提供者，使用协程实现与userProfileProviderOC不能同时存在userProfileProviderOC使用闭包实现
        EaseChatUIKitContext.shared?.userProfileProvider = self
        EaseChatUIKitContext.shared?.userProfileProviderOC = nil
        //groupProvider原理同上
        EaseChatUIKitContext.shared?.groupProfileProvider = self
        EaseChatUIKitContext.shared?.groupProfileProviderOC = nil
    }
    
    private func callKitSet() {
        let callConfig = EaseCallConfig()
        callConfig.agoraAppId = "15cb0d28b87b425ea613fc46f7c9f974"
        callConfig.enableRTCTokenValidate = true
        EaseCallManager.shared().initWith(callConfig, delegate: self)
        EaseCallManager.shared()
    }

    private func loadViewControllers() {

        let nav1 = UINavigationController(rootViewController: self.chats)
        let nav2 = UINavigationController(rootViewController: self.contacts)
        let nav3 = UINavigationController(rootViewController: self.me)
        self.viewControllers = [nav1, nav2,nav3]
//        self.tabBar.isTranslucent = false
        self.view.backgroundColor = UIColor.theme.neutralColor98
        self.tabBar.backgroundColor = UIColor.theme.barrageDarkColor8
        self.tabBar.barTintColor = UIColor.theme.barrageDarkColor8
//        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
//        blurView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: BottomBarHeight+49)
//        blurView.alpha = 0.8
//        blurView.insetsLayoutMarginsFromSafeArea = false
//        blurView.layoutMargins = .zero
//        self.tabBar.insertSubview(blurView, at: 0)
        self.tabBar.isTranslucent = true
        self.tabBar.barStyle = .default
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
    }

}

extension MainViewController: ThemeSwitchProtocol {
    
    func switchTheme(style: EaseChatUIKit.ThemeStyle) {
//        if let blur = self.tabBar.viewWithTag(0) as? UIVisualEffectView {
//            blur.effect = style == .dark ? UIBlurEffect(style: .dark): UIBlurEffect(style: .light)
//            blur.alpha = style == .dark ? 1:0.8
//        }
        self.tabBar.barTintColor = style == .dark ? UIColor.theme.barrageLightColor8:UIColor.theme.barrageDarkColor8
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.tabBar.backgroundColor = style == .dark ? UIColor.theme.barrageLightColor8:UIColor.theme.barrageDarkColor8
        
        var chatsImage = UIImage(named: "tabbar_chats")
        chatsImage = chatsImage?.withTintColor(style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5, renderingMode: .alwaysOriginal)
        let selectedChatsImage = chatsImage?.withTintColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, renderingMode: .alwaysOriginal)
        self.chats.tabBarItem = UITabBarItem(title: "Chats".localized(), image: chatsImage, selectedImage: selectedChatsImage)
        
        var contactImage = UIImage(named: "tabbar_contacts")
        contactImage = contactImage?.withTintColor(style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5, renderingMode: .alwaysOriginal)
        let selectedContactImage = contactImage?.withTintColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, renderingMode: .alwaysOriginal)
        self.contacts.tabBarItem = UITabBarItem(title: "Contacts".localized(), image: contactImage, selectedImage: selectedContactImage)
        
        var meImage = UIImage(named: "tabbar_mine")
        meImage = meImage?.withTintColor(style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor5, renderingMode: .alwaysOriginal)
        let selectedMeImage = meImage?.withTintColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, renderingMode: .alwaysOriginal)
        self.me.tabBarItem = UITabBarItem(title: "Me".localized(), image: meImage, selectedImage: selectedMeImage)
    }
    
}

//MARK: - EaseProfileProvider for conversations&contacts usage.
//For example using conversations controller,as follows.
extension MainViewController: EaseProfileProvider,EaseGroupProfileProvider {
    //MARK: - EaseProfileProvider
    func fetchProfiles(profileIds: [String]) async -> [any EaseChatUIKit.EaseProfileProtocol] {
        return await withTaskGroup(of: [EaseChatUIKit.EaseProfileProtocol].self, returning: [EaseChatUIKit.EaseProfileProtocol].self) { group in
            var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
            group.addTask {
                var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
                let result = await self.requestUserInfos(profileIds: profileIds)
                if let infos = result {
                    resultProfiles.append(contentsOf: infos)
                }
                return resultProfiles
            }
            //Await all task were executed.Return values.
            for await result in group {
                resultProfiles.append(contentsOf: result)
            }
            return resultProfiles
        }
    }
    //MARK: - EaseGroupProfileProvider
    func fetchGroupProfiles(profileIds: [String]) async -> [any EaseChatUIKit.EaseProfileProtocol] {
        
        return await withTaskGroup(of: [EaseChatUIKit.EaseProfileProtocol].self, returning: [EaseChatUIKit.EaseProfileProtocol].self) { group in
            var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
            group.addTask {
                var resultProfiles: [EaseChatUIKit.EaseProfileProtocol] = []
                let result = await self.requestGroupsInfo(groupIds: profileIds)
                if let infos = result {
                    resultProfiles.append(contentsOf: infos)
                }
                return resultProfiles
            }
            //Await all task were executed.Return values.
            for await result in group {
                resultProfiles.append(contentsOf: result)
            }
            return resultProfiles
        }
    }
    
    private func requestUserInfos(profileIds: [String]) async -> [EaseProfileProtocol]? {
        var unknownIds = [String]()
        var resultProfiles = [EaseProfileProtocol]()
        for profileId in profileIds {
            if let profile = EaseChatUIKitContext.shared?.userCache?[profileId] {
                if profile.nickname.isEmpty {
                    unknownIds.append(profile.id)
                } else {
                    resultProfiles.append(profile)
                }
            } else {
                unknownIds.append(profileId)
            }
        }
        if unknownIds.isEmpty {
            return resultProfiles
        }
        let result = await ChatClient.shared().userInfoManager?.fetchUserInfo(byId: unknownIds)
        if result?.1 == nil,let infoMap = result?.0 {
            for (userId,info) in infoMap {
                let profile = EaseChatProfile()
                let nickname = info.nickname ?? ""
                profile.id = userId
                profile.nickname = nickname
                if let remark = ChatClient.shared().contactManager?.getContact(userId)?.remark {
                    profile.remark = remark
                }
                profile.avatarURL = info.avatarUrl ?? ""
                resultProfiles.append(profile)
                if (EaseChatUIKitContext.shared?.userCache?[userId]) != nil {
                    profile.updateFFDB()
                } else {
                    profile.insert()
                }
                EaseChatUIKitContext.shared?.userCache?[userId] = profile
            }
            return resultProfiles
        }
        return []
    }
    
    private func requestGroupsInfo(groupIds: [String]) async -> [EaseProfileProtocol]? {
        var resultProfiles = [EaseProfileProtocol]()
        let groups = ChatClient.shared().groupManager?.getJoinedGroups() ?? []
        for groupId in groupIds {
            if let group = groups.first(where: { $0.groupId == groupId }) {
                let profile = EaseChatProfile()
                profile.id = groupId
                profile.nickname = group.groupName
                profile.avatarURL = group.settings.ext
                resultProfiles.append(profile)
                EaseChatUIKitContext.shared?.groupCache?[groupId] = profile
            }

        }
        return resultProfiles
    }
}
//MARK: - ConversationEmergencyListener
extension  MainViewController: ConversationEmergencyListener {
    func onResult(error: EaseChatUIKit.ChatError?, type: EaseChatUIKit.ConversationEmergencyType) {
        //show toast or alert,then process
    }
    
    func onConversationLastMessageUpdate(message: EaseChatUIKit.ChatMessage, info: EaseChatUIKit.ConversationInfo) {
        //Latest message updated on the conversation.
    }
    
    func onConversationsUnreadCountUpdate(unreadCount: UInt) {
        self.chats.tabBarItem.badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
    }
}
//MARK: - ContactEmergencyListener
extension MainViewController: ContactEmergencyListener {
    func onResult(error: EaseChatUIKit.ChatError?, type: EaseChatUIKit.ContactEmergencyType, operatorId: String) {
        if type != .setRemark {
            if let newFriends = UserDefaults.standard.value(forKey: "EaseChatUIKit_contact_new_request") as?  Dictionary<String,Double> {
                self.contacts.tabBarItem.badgeValue = newFriends.count > 0 ? "\(newFriends.count)":nil
            } else {
                self.contacts.tabBarItem.badgeValue = nil
            }
        }
    }
}

//MARK: - EaseCallDelegate
extension MainViewController: EaseCallDelegate {
    
    func callDidEnd(_ aChannelName: String, reason aReason: EaseCallEndReason, time aTm: Int32, type aType: EaseCallType) {
        var alertMessage = "";
        switch aReason {
        case .handleOnOtherDevice:
            alertMessage = "otherDevice".localized()
        case .busy:
            alertMessage = "remoteBusy".localized()
        case .refuse:
            alertMessage = "refuseCall".localized()
        case .cancel:
            alertMessage = "cancelCall".localized()
                break;
        case .remoteCancel:
            alertMessage = "callCancel".localized()
                break;
        case .remoteNoResponse:
            alertMessage = "remoteNoResponse".localized()
                break;
        case .noResponse:
            alertMessage = "noResponse".localized()
                break;
        case .hangup:
            alertMessage = "\("callendPrompt".localized()) \(aTm)s"
                break;
        @unknown default:
            break
        }
        DispatchQueue.main.asyncAfter(wallDeadline: .now()+0.5) {
            UIViewController.currentController?.showToast(toast: alertMessage)
        }
    }
    
    func multiCallDidInviting(withCurVC vc: UIViewController, excludeUsers users: [String]?, ext aExt: [AnyHashable : Any]?) {
        if let groupId = aExt?["groupId"] as? String {
            let inviteVC = MineCallInviteUsersController(groupId: groupId, profiles: users == nil ? []:users!.map({
                let profile = EaseProfile()
                profile.id = $0
                return profile
            })) { users in
                EaseCallManager.shared().startInviteUsers(users, ext: ["groupId":groupId])
            }
            UIViewController.currentController?.present(inviteVC, animated: true)
        }
        
    }

    
    func callDidReceive(_ aType: EaseCallType, inviter user: String, ext aExt: [AnyHashable : Any]?) {
        self.mapUserDisplayInfo(userId: user)
    }
    
    func callDidOccurError(_ aError: EaseCallError) {
        
    }
    
    func callDidRequestRTCToken(forAppId aAppId: String, channelName aChannelName: String, account aUserAccount: String, uid aAgoraUid: Int) {
        EasemobBusinessRequest.shared.sendGETRequest(api: .fetchRTCToken(aChannelName, aUserAccount), params: [:]) { result, error in
            if error == nil {
                if let code = result?["code"] as? Int,code == 200 {
                    if let token = result?["accessToken"] as? String{
                        if let callUserId = result?["agoraUid"] as? String {
                            EaseCallManager.shared().setRTCToken(token, channelName: aChannelName, uid: UInt(callUserId) ?? 0)
                        }
                    }
                }
            } else {
                consoleLogInfo("EaseCallKit callDidRequestRTCToken error:\(error?.localizedDescription ?? "")", type: .error)
            }
        }
    }
    
    func remoteUserDidJoinChannel(_ aChannelName: String, uid aUid: Int, username aUserName: String?) {
        if let otherPartUserId = aUserName {
            self.mapUserDisplayInfo(userId: otherPartUserId)
        } else {
            self.setUserInfos(channelName: aChannelName)
        }
        
    }
    
    private func setUserInfos(channelName: String) {
        EasemobBusinessRequest.shared.sendGETRequest(api: .mirrorCallUserIdToChatUserId(channelName), params: [:]) { result, error in
            if error == nil {
                if let code = result?["code"] as? Int,code == 200 {
                    if let users = result?["result"] as? Dictionary<String,String>,let channelName = result?["channelName"] as? String {
                        var userMap = [NSNumber:String]()
                        for (callUserId, chatUserId) in users {
                            let uid = Int(callUserId) ?? 0
                            userMap[NSNumber(integerLiteral: uid)] = chatUserId
                            self.mapUserDisplayInfo(userId: chatUserId)
                        }
                        EaseCallManager.shared().setUsers(userMap, channelName: channelName)
                    }
                }
            } else {
                consoleLogInfo("EaseCallKit remoteUserDidJoinChannel error:\(error?.localizedDescription ?? "")", type: .error)
            }
        }
    }
    
    private func mapUserDisplayInfo(userId: String) {
        if let cacheUser = EaseChatUIKitContext.shared?.chatCache?[userId] {
            var nickname = cacheUser.remark
            if nickname.isEmpty {
                nickname = cacheUser.nickname
            }
            if nickname.isEmpty {
                nickname = cacheUser.id
            }
            
            let user = EaseCallUser(nickName: nickname, image: URL(string: cacheUser.avatarURL) ?? URL(string: "https://www.baidu.com")!)
            EaseCallManager.shared().getEaseCallConfig().setUser(userId, info: user)
        } else {
            if let cacheUser = EaseChatUIKitContext.shared?.userCache?[userId] {
                var nickname = cacheUser.remark
                if nickname.isEmpty {
                    nickname = cacheUser.nickname
                }
                if nickname.isEmpty {
                    nickname = cacheUser.id
                }
                
                let user = EaseCallUser(nickName: nickname, image: URL(string: cacheUser.avatarURL) ?? URL(string: "https://www.baidu.com")!)
                EaseCallManager.shared().getEaseCallConfig().setUser(userId, info: user)
            } else {
                self.fetchUserInfo(userId: userId)
            }
        }
    }
    
    private func fetchUserInfo(userId: String) {
        ChatClient.shared().userInfoManager?.fetchUserInfo(byId: [userId], type: [0,1], completion: { userMap, error in
            if error == nil,let user = userMap?[userId] {
                let callUser = EaseCallUser(nickName: user.nickname ?? "", image: URL(string: user.avatarUrl ?? "") ?? URL(string: "https://www.baidu.com")!)
                EaseCallManager.shared().getEaseCallConfig().setUser(userId, info: callUser)
                let cache = EaseChatProfile()
                cache.id = userId
                cache.nickname = user.nickname ?? userId
                cache.avatarURL = user.avatarUrl ?? ""
                cache.insert()
                EaseChatUIKitContext.shared?.userCache?[userId] = cache
            } else {
                consoleLogInfo("EaseCallKit mapUserDisplayInfo error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    func callDidJoinChannel(_ aChannelName: String, uid aUid: UInt) {
        
    }
    
    
}