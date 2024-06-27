//
//  MineGroupDetailViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/19.
//

import UIKit
import EaseChatUIKit
import EaseCallKit

final class MineGroupDetailViewController: GroupInfoViewController {
    
    override func cleanHistoryMessages() {
        DialogManager.shared.showAlert(title: "group_details_button_clearchathistory".chat.localize, content: "", showCancel: true, showConfirm: true) { [weak self] _ in
            guard let `self` = self else { return }
            self.showToast(toast: "Clean successful!".localized())
            ChatClient.shared().chatManager?.getConversationWithConvId(self.chatGroup.groupId)?.deleteAllMessages(nil)
            NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_clean_history_messages"), object: self.chatGroup.groupId)
        }
    }

    override func viewDidLoad() {
        Appearance.contact.detailExtensionActionItems = [ContactListHeaderItem(featureIdentify: "Chat", featureName: "Chat".chat.localize, featureIcon: UIImage(named: "chatTo", in: .chatBundle, with: nil)),ContactListHeaderItem(featureIdentify: "AudioCall", featureName: "AudioCall".chat.localize, featureIcon: UIImage(named: "voice_call", in: .chatBundle, with: nil)),ContactListHeaderItem(featureIdentify: "VideoCall", featureName: "VideoCall".chat.localize, featureIcon: UIImage(named: "video_call", in: .chatBundle, with: nil)),ContactListHeaderItem(featureIdentify: "SearchMessages", featureName: "SearchMessages".chat.localize, featureIcon: UIImage(named: "search_history_messages", in: .chatBundle, with: nil))]
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.header.status.isHidden = true
    }
    

    override func headerActions() {
        if let chat = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "Chat" }) {
            chat.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
        if let search = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "SearchMessages" }) {
            search.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
        if let audioCall = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "AudioCall" }) {
            audioCall.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
        if let videoCall = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "VideoCall" }) {
            videoCall.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
    }
    
    override func processHeaderActionEvents(item: any ContactListHeaderItemProtocol) {
        switch item.featureIdentify {
        case "Chat": self.alreadyChat()
        case "AudioCall": self.groupCall()
        case "VideoCall": self.groupCall()
        case "SearchMessages": self.searchHistoryMessages()
        default: break
        }
    }
    
    private func groupCall() {
        guard let groupId = self.chatGroup.groupId,let userInfo = EaseChatUIKitContext.shared?.currentUser else {
            self.showToast(toast: "Chat group id is nil")
            return
        }
        let vc = MineCallInviteUsersController(groupId: groupId,profiles: [userInfo]) { [weak self] users in
            self?.startGroupCall(users: users)
        }
        self.present(vc, animated: true)
    }

    private func startGroupCall(users: [String]) {
        if let groupId = self.chatGroup.groupId {
            EaseCallManager.shared().startInviteUsers(users, ext: ["groupId":groupId]) {  [weak self] callId, callError in
                if callError != nil {
                    self?.showToast(toast: "\(callError?.errDescription ?? "")")
                }
            }
        }
    }
    
    override func fetchGroupInfo(groupId: String) {
        // Fetch group information from the service
        self.service.fetchGroupInfo(groupId: groupId) { [weak self] group, error in
            guard let `self` = self else { return }
            if error == nil, let group = group {
                self.chatGroup = group
                let showName = self.chatGroup.groupName.isEmpty ? groupId:self.chatGroup.groupName
                self.header.nickName.text = showName
                self.header.userState = .offline
                self.header.detailText = groupId
                self.menuList.reloadData()
                let profile = EaseProfile()
                profile.id = self.chatGroup.groupId
                profile.nickname = self.chatGroup.groupName
                if !self.chatGroup.groupName.isEmpty {
                    profile.avatarURL = self.chatGroup.settings.ext
                    self.header.avatarURL = self.chatGroup.settings.ext
                }
                EaseChatUIKitContext.shared?.updateCache(type: .group, profile: profile)
            } else {
                self.chatGroup = ChatGroup(id: groupId)
                self.showToast(toast: "\(error?.errorDescription ?? "")")
            }
           
        }
    }
}
