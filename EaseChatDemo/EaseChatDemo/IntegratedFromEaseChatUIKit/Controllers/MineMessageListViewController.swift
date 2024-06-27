//
//  MineMessageListViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/14.
//

import UIKit
import EaseChatUIKit
import EaseCallKit

let callIdentifier = "msgType"

let callValue = "rtcCallWithAgora"

final class MineMessageListViewController: MessageListController {
    
    private var otherPartyStatus = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if self.chatType == .chat {
            self.subscribeUserStatus()
        }
    }
    
    deinit {
        PresenceManager.shared.unsubscribe(members: [self.profile.id], completion: nil)
        EaseChatUIKitContext.shared?.cleanCache(type: .chat)
        URLPreviewManager.caches.removeAll()
    }
    
    @objc func subscribeUserStatus() {
        PresenceManager.shared.usersStatusChanged = { [weak self] users in
            guard let `self` = self else { return }
            if users.contains(self.profile.id), let presence = PresenceManager.shared.presences[self.profile.id] {
                self.showUserStatus(state: PresenceManager.fetchStatus(presence: presence))
            }
        }
        PresenceManager.shared.subscribe(members: [self.profile.id]) { [weak self] presences, error in
            if let presence = presences?.first {
                self?.showUserStatus(state: PresenceManager.fetchStatus(presence: presence))
            }
        }
    }
    
    override func performTypingTask() {
        if self.chatType == .chat {
            DispatchQueue.main.async {
                self.navigation.subtitle = self.otherPartyStatus
                self.navigation.title = self.navigation.title
            }
        }
    }
    
    private func showUserStatus(state: PresenceManager.State) {
        let subtitle = PresenceManager.showStatusMap[state] ?? ""
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
        self.otherPartyStatus = subtitle
        self.navigation.subtitle = subtitle
        self.navigation.title = self.navigation.title

    }
    
    /**
     Updates the user state and sets it to the specified state.
     
     - Parameters:
        - state: The new user state.
     */
    @MainActor @objc public func updateUserState(state: UserState) {
        self.navigation.userState = state
    }
    
    override func rightImages() -> [UIImage] {
        var images = [UIImage(named: "pinned_messages", in: .chatBundle, with: nil)!,UIImage(named: "message_action_topic", in: .chatBundle, with: nil)!,UIImage(named: "call", in: .chatBundle, with: nil)!]
        if self.chatType == .chat {
            images = [UIImage(named: "call", in: .chatBundle, with: nil)!]
        } else {
            if !Appearance.chat.contentStyle.contains(.withMessageThread) {
                if images.count > 0 {
                    images.remove(at: 0)
                }
            }
        }
        return images
    }
    
    override func rightItemsAction(indexPath: IndexPath?) {
        guard let idx = indexPath else { return }
        switch idx.row {
        case 0: self.showPinnedMessages()
        case 1:
            if self.chatType == .chat {
                self.callAction()
            } else {
                !Appearance.chat.contentStyle.contains(.withMessageThread) ? self.callAction():self.viewTopicList()
            }
        case 2: self.callAction()
        default:
            break
        }
    }
    
    private func callAction() {
        if self.chatType == .chat {
            DialogManager.shared.showActions(actions: [ActionSheetItem(title: "Audio Call".localized(), type: .normal, tag: "AudioCall"),ActionSheetItem(title: "Video Call".localized(), type: .normal, tag: "VideoCall")]) { [weak self] item in
                self?.processItemAction(item: item)
            }
        } else {
            self.processItemAction(item: ActionSheetItem())
        }
    }
    
    private func processItemAction(item: ActionSheetItemProtocol) {
        if self.chatType == .chat {
            var callType = EaseCallType.type1v1Audio
            if item.tag == "VideoCall".localized() {
                callType = .type1v1Video
            }
            self.startSingleCall(callType: callType)
        } else {
            guard let userInfo = EaseChatUIKitContext.shared?.currentUser else { return }
            let vc = MineCallInviteUsersController(groupId: self.profile.id,profiles: [userInfo]) { [weak self] users in
                let user = EaseChatUIKitContext.shared?.chatCache?[EaseChatUIKitContext.shared?.currentUserId ?? ""]
                var nickname = user?.id ?? ""
                if let realName = user?.nickname,!realName.isEmpty {
                    nickname = realName
                }
                if let remark = user?.remark,!remark.isEmpty {
                    nickname = remark
                }
                let text = "\(nickname)"+" start a multi call".localized()
                if let callMessage = self?.viewModel.constructMessage(text: text, type: .text, extensionInfo: ["ext":["groupId":self?.profile.id],"msgType":callValue]) {
                    callMessage.direction = .send
                    callMessage.timestamp = Int64(Date().timeIntervalSince1970*1000)
                    
                    callMessage.chatType = .groupChat
                    callMessage.status = .succeed
                    callMessage.isRead = true
                    ChatClient.shared().chatManager?.getConversationWithConvId(self?.profile.id)?.insert(callMessage, error: nil)
                    self?.viewModel.driver?.showMessage(message: callMessage)
                }
                self?.startGroupCall(users: users)
            }
            
            self.present(vc, animated: true)
            
        }
        
    }
    
    private func startSingleCall(callType: EaseCallType) {
        EaseCallManager.shared().startSingleCall(withUId: self.profile.id, type: callType, ext: nil) { [weak self]  _, _ in
            if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self?.profile.id) {
                let messageId = conversation.latestMessage.messageId
                conversation.loadMessagesStart(fromId: messageId, count: 1, searchDirection:  messageId.isEmpty ? .down:.up) { messages, error in
                    if let message = messages?.first {
                        self?.messageContainer.showMessage(message: message)
                    }
                }
            }
        }
    }
    
    private func startGroupCall(users: [String]) {
        EaseCallManager.shared().startInviteUsers(users, ext: ["groupId":self.profile.id]) {  [weak self] _, _ in
            if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self?.profile.id) {
                let messageId = conversation.latestMessage.messageId
                conversation.loadMessagesStart(fromId: messageId, count: 1, searchDirection:  messageId.isEmpty ? .down:.up) { messages, error in
                    if let message = messages?.first {
                        self?.messageContainer.showMessage(message: message)
                    }
                }
            }
        }
        
    }

    override func filterMessageActions(message: MessageEntity) -> [ActionSheetItemProtocol] {
        if let ext = message.message.ext,let value = ext[callIdentifier] as? String,value == callValue {
            return [
                ActionSheetItem(title: "barrage_long_press_menu_delete".chat.localize, type: .normal,tag: "Delete",image: UIImage(named: "message_action_delete", in: .chatBundle, with: nil)),
                ActionSheetItem(title: "barrage_long_press_menu_multi_select".chat.localize, type: .normal,tag: "MultiSelect",image: UIImage(named: "message_action_multi_select", in: .chatBundle, with: nil)),
                ActionSheetItem(title: "barrage_long_press_menu_forward".chat.localize, type: .normal,tag: "Forward",image: UIImage(named: "message_action_forward", in: .chatBundle, with: nil))
            ]
        } else {
            return super.filterMessageActions(message: message)
        }
    }

}
