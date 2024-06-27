//
//  ViewController.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit
import SwiftFFDBHotFix


let loginSuccessfulSwitchMainPage = "loginSuccessfulSwitchMainPage"
let backLoginPage = "backLoginPage"

final class LoginViewController: UIViewController {
    
    private let regular = "^((1[1-9][0-9])|(14[5|7])|(15([0-3]|[5-9]))|(17[013678])|(18[0,5-9]))d{8}$"
    
    private var code = ""
        
    @UserDefault("EaseChatDemoServerConfig", defaultValue: Dictionary<String,String>()) private var config
    
    private lazy var background: UIImageView = {
        UIImageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)).contentMode(.scaleAspectFill)
    }()
    
    private lazy var appName: UILabel = {
        UILabel(frame: CGRect(x: 30, y: 187, width: ScreenWidth - 60, height: 35)).font(UIFont(name: "PingFangSC-Medium", size: 24)).text("Login Easemob Chat".localized())
    }()
    
    lazy var sdkVersion: UILabel = {
        UILabel(frame: CGRect(x: self.view.frame.width-73.5, y: self.appName.frame.minY+8, width: 43, height: 18)).cornerRadius(Appearance.avatarRadius).font(UIFont.theme.bodyExtraSmall).textColor(UIColor.theme.neutralColor98).textAlignment(.center)
    }()
    
    private lazy var phoneNumber: UITextField = {
        UITextField(frame: CGRect(x: 30, y: self.appName.frame.maxY+22, width: ScreenWidth-60, height: 48)).delegate(self).tag(11).font(UIFont.theme.bodyLarge).placeholder("Mobile Number".localized()).leftView(UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 48)), .always).cornerRadius(Appearance.avatarRadius).clearButtonMode(.whileEditing)
    }()
    
    private lazy var pinCode: UITextField = {
        UITextField(frame: CGRect(x: 30, y: self.phoneNumber.frame.maxY+24, width: ScreenWidth-60, height: 48)).delegate(self).tag(12).font(UIFont.theme.bodyLarge).placeholder("PinCodePlaceHolder".localized()).leftView(UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 48)), .always).cornerRadius(Appearance.avatarRadius)
    }()
    
    private lazy var right: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 0, y: 0, width: 104, height: 48)).title("Get Code".localized(), .normal).addTargetFor(self, action: #selector(getPinCode), for: .touchUpInside).font(.systemFont(ofSize: 14, weight: .medium)).backgroundColor(.clear)
    }()
    
    private lazy var login: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 30, y: self.pinCode.frame.maxY+24, width: ScreenWidth - 60, height: 48)).cornerRadius(Appearance.avatarRadius).title("Login".localized(), .normal).textColor(.white, .normal).font(.systemFont(ofSize: 16, weight: .semibold)).addTargetFor(self, action: #selector(loginAction), for: .touchUpInside)
    }()
    
    private lazy var loginContainer: UIView = {
        UIView(frame: CGRect(x: 30, y: self.pinCode.frame.maxY+24, width: ScreenWidth - 60, height: 48)).backgroundColor(.white)
    }()
    
    private lazy var agree: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: self.login.frame.minX+5, y: self.login.frame.maxY+16, width: 20, height: 20)).image(UIImage(named: "selected"), .selected).image(UIImage(named: "unselected"), .normal).addTargetFor(self, action: #selector(agreeAction(sender:)), for: .touchUpInside)
    }()
    
    private lazy var protocolContainer: UITextView = {
        UITextView(frame: CGRect(x: self.agree.frame.maxX+4, y: self.login.frame.maxY+10, width: ScreenWidth-90-4, height: 58)).attributedText(self.protocolContent).isEditable(false).backgroundColor(.clear)
    }()
    
    public private(set) lazy var loadingView: LoadingView = {
        self.createLoading()
    }()
    
    /**
     Creates a loading view.
     
     - Returns: A `LoadingView` instance.
     */
    @objc public func createLoading() -> LoadingView {
        LoadingView(frame: self.view.bounds)
    }
    
    private var count = 60
    
    private lazy var timer: GCDTimer? = {
        GCDTimerMaker.exec({
            self.timerFire()
        }, interval: 1, repeats: true)
    }()
    
    private var protocolContent: NSAttributedString = NSAttributedString {
        AttributedText("Please tick to agree".localized()).font(.systemFont(ofSize: 12, weight: .regular)).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor8:UIColor.theme.neutralColor3).lineSpacing(5)
        Link("Service".localized(), url: URL(string: "https://www.easemob.com/terms/im")!).foregroundColor(Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).font(.systemFont(ofSize: 12, weight: .medium)).underline(.single,color: Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).lineSpacing(5)
        AttributedText(" and ".localized()).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor8:UIColor.theme.neutralColor3).font(.systemFont(ofSize: 12, weight: .regular)).foregroundColor(Color(0x3C4267)).lineSpacing(5)
        Link("Privacy Policy".localized(), url: URL(string: "https://www.easemob.com/protocol")!).foregroundColor(Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).font(.systemFont(ofSize: 12, weight: .medium)).underline(.single,color: Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).lineSpacing(5)
    }
    
    private lazy var serverConfig: UIButton = {
        UIButton(frame: CGRect(x: 140, y: ScreenHeight-100, width: ScreenWidth-280, height: 20)).backgroundColor(.clear).font(UIFont.theme.labelMedium).title("Server Config".localized(), .normal).addTargetFor(self, action: #selector(changeServerConfig), for: .touchUpInside)
    }()
    
    @UserDefault("EaseChatDemoServerConfig", defaultValue: Dictionary<String,String>()) private var serverInfo
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.window?.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubViews([self.background,self.appName,self.sdkVersion,self.phoneNumber,self.pinCode,self.loginContainer,self.login,self.agree,self.protocolContainer,self.serverConfig,self.loadingView])
        self.loadingView.isHidden = true
        self.serverConfig.isHidden = true
        self.right.titleLabel?.textAlignment = .right
        self.sdkVersion.text = "V\(ChatClient.shared().version)"
        
        self.fieldSetting()
        if let debugMode = self.serverInfo["debug_mode"],debugMode == "1"{
            self.serverConfig.isHidden = false
            self.resetDisplay()
        }
        // Do any additional setup after loading the view.
        self.setContainerShadow()
        self.addGesture()
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    private func addGesture() {
        self.appName.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showServerConfig))
        tap.numberOfTapsRequired = 3
        self.appName.addGestureRecognizer(tap)
    }
    
    @objc private func showServerConfig() {
        self.serverConfig.isHidden = !self.serverConfig.isHidden
        self.serverInfo["debug_mode"] = self.serverConfig.isHidden ? "0":"1"
        self.resetDisplay()
    }
    
    private func resetDisplay() {
        if let debugMode = self.serverInfo["debug_mode"],debugMode != "1" {
            self.phoneNumber.placeholder = "Mobile Number".localized()
            self.pinCode.placeholder = "PinCodePlaceHolder".localized()
            self.pinCode.keyboardType = .numberPad
            self.phoneNumber.keyboardType = .numberPad
            self.right.isHidden = false
            //此方法仅用于有限情况下内部调试，正常使用不需要
            ChatClient.shared().options.setValue(true, forKey: "enableDnsConfig")
            ChatClient.shared().changeAppkey(AppKey)
        } else {
            if let applicationKey = self.serverInfo["application"] {
                ChatClient.shared().changeAppkey(applicationKey)
            }
            if let customServer = self.serverInfo["use_custom_server"], customServer == "1" {
                ChatClient.shared().options.setValue(false, forKey: "enableDnsConfig")
                ChatClient.shared().options.setValue(true, forKey: "usingHttpsOnly")
            }
            self.right.isHidden = true
            self.phoneNumber.placeholder = "EeaseMobID".localized()
            self.pinCode.placeholder = "Password".localized()
            self.phoneNumber.keyboardType = .namePhonePad
            self.pinCode.keyboardType = .namePhonePad
        }
    }
    
    @objc private func changeServerConfig() {
        let vc = ServerConfigViewController()
        self.view.window?.backgroundColor = .black
        self.present(vc, animated: true)
    }
    
    private func fieldSetting() {
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 104, height: 48)).backgroundColor(.clear)
        rightView.addSubview(self.right)
        self.pinCode.rightView = rightView
        self.pinCode.rightViewMode = .always
        self.pinCode.keyboardType = .numberPad
        self.phoneNumber.keyboardType = .numberPad
    }
    
    private func setContainerShadow() {
        self.loginContainer.layer.cornerRadius = CGFloat(Appearance.avatarRadius.rawValue)
        self.loginContainer.layer.shadowRadius = 8
        self.loginContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.loginContainer.layer.shadowColor = UIColor(red: 0, green: 0.55, blue: 0.98, alpha: 0.2).cgColor
        self.loginContainer.layer.shadowOpacity = 1
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    @objc func timerFire() {
        DispatchQueue.main.async {
            self.count -= 1
            if self.count <= 0 {
                self.timer?.suspend()
                self.getAgain()
            } else { self.startCountdown() }
        }
    }
    
    private func getAgain() {
        self.right.isEnabled = true
        self.right.setTitle("Get Code".localized(), for: .normal)
        self.count = 60
    }
    
    private func startCountdown() {
        self.right.isEnabled = false
        self.right.setTitle("Get After".localized()+"(\(self.count)s)", for: .disabled)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
    }
    
    @objc private func loginAction() {
        self.view.endEditing(true)
        if self.serverConfig.isHidden {
            if self.phoneNumber.text?.count ?? 0 != 11,!(self.phoneNumber.text ?? "").chat.isMatchRegular(expression: self.regular) {
                self.showToast(toast: "PhoneError".localized())
                return
            }
            if self.pinCode.text?.count ?? 0 != 6 {
                self.showToast(toast: "PinCodeError".localized())
                return
            }
        }
        if !self.agree.isSelected {
            self.showToast(toast:"AgreeProtocol".localized())
            return
        }
        self.loginRequest()
    }
    
    @objc private func loginRequest() {
        if !self.serverConfig.isHidden {
            guard let userId = self.phoneNumber.text else {
                self.showToast(toast: "UserIdError".localized())
                return
            }
            guard let password = self.pinCode.text else {
                self.showToast(toast: "PasswordError".localized())
                return
            }
            self.loadingView.startAnimating()
            ChatClient.shared().fetchToken(withUsername: userId.lowercased(), password: password) {[weak self] token, error in
                self?.loadingView.stopAnimating()
                if error ==  nil,let chatToken = token {
                    let user = EaseChatProfile()
                    user.id = userId
                    self?.login(user: user, token: chatToken)
                    user.insert()
                } else {
                    self?.showToast(toast: "PasswordError".localized())
                }
            }
        } else {
            guard let phone = self.phoneNumber.text else {
                self.showToast(toast: "PhoneError".localized())
                return
            }
            guard let code = self.pinCode.text else {
                self.showToast(toast: "PinCodeError".localized())
                return
            }
            self.loadingView.startAnimating()
            EasemobBusinessRequest.shared.sendPOSTRequest(api: .login(()), params: ["phoneNumber":phone,"smsCode":code]) { [weak self] result, error in
                if error == nil {
                    if let userId = result?["chatUserName"] as? String,let token = result?["token"] as? String{
                        let user = EaseChatProfile()
                        user.id = userId
                        user.avatarURL = (result?["avatarUrl"] as? String) ?? ""
                        self?.login(user: user, token: token)
                        user.insert()
                    }
                } else {
                    self?.loadingView.stopAnimating()
                    self?.showToast(toast: "PhoneError".localized())
                }
            }
        }
    }
    
    private func login(user: EaseProfileProtocol,token: String) {
        if let dbPath = FMDBConnection.databasePath,dbPath.isEmpty {
            FMDBConnection.databasePath = String.documentsPath+"/EaseMobDemo/"+"\(AppKey)/"+user.id+".db"
        }
        self.loadCache()
        EaseChatUIKitClient.shared.login(user: user, token: token) { [weak self] error in
            self?.loadingView.stopAnimating()
            if error == nil {
                if let profiles = EaseChatProfile.select(where: "id = '\(user.id)'") as? [EaseChatProfile] {
                    if profiles.first != nil {
                        if let profile = profiles.first {
                            (user as? EaseChatProfile)?.update()
                            EaseChatUIKitContext.shared?.currentUser = profiles.first
                            EaseChatUIKitContext.shared?.userCache?[profile.id] = profile
                        }
                    }
                } else {
                    EaseChatUIKitContext.shared?.currentUser = user
                    EaseChatUIKitContext.shared?.userCache?[user.id] = user
                }
                self?.fillCache()
                self?.entryHome()
            } else {
                self?.showToast(toast: error?.errorDescription ?? "")
            }
        }
    }
    
    private func loadCache() {
        if let profiles = EaseChatProfile.select(where: nil) as? [EaseChatProfile] {
            for profile in profiles {
                if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(profile.id) {
                    if conversation.type == .chat {
                        EaseChatUIKitContext.shared?.userCache?[profile.id] = profile
                    }
                }
                if profile.id == ChatClient.shared().currentUsername ?? "" {
                    EaseChatUIKitContext.shared?.currentUser = profile
                    EaseChatUIKitContext.shared?.userCache?[profile.id] = profile
                }
            }
        }
        
    }
    
    private func fillCache() {

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
    }
    
    
    @objc private func getPinCode() {
        self.view.endEditing(true)
        if self.phoneNumber.text?.count ?? 0 != 11,!(self.phoneNumber.text ?? "").chat.isMatchRegular(expression: self.regular) {
            self.showToast(toast:"PhoneError".localized())
            return
        }
        
        guard let phoneNum = self.phoneNumber.text else {
            self.showToast(toast: "PinCodeError".localized())
            return
        }
        self.timer?.resume()
        EasemobBusinessRequest.shared.sendPOSTRequest(api: .verificationCode((phoneNum)), params: [:]) { [weak self] result, error in
            if error == nil {
                self?.timer?.cancel()
                guard let code = result?["code"] as? Int else { return }
                self?.code = "\(code)"
                self?.showToast(toast:"获取成功")
            } else {
                self?.showToast(toast:error?.localizedDescription ?? "")
            }
        }
    }
    
    @objc private func agreeAction(sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @objc private func entryHome() {
        NotificationCenter.default.post(name: NSNotification.Name(loginSuccessfulSwitchMainPage), object: nil)
    }
    
}

extension LoginViewController: ThemeSwitchProtocol {
    func switchTheme(style: ThemeStyle) {
        self.protocolContainer.linkTextAttributes = [.foregroundColor:(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5)]
        self.background.image = style == .dark ? UIImage(named: "login_bg_dark") : UIImage(named: "login_bg")
        self.appName.textColor = style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
        self.sdkVersion.backgroundColor = style == .dark ? UIColor.theme.barrageDarkColor2:UIColor.theme.barrageLightColor2
        self.phoneNumber.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.pinCode.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.phoneNumber.textColor = style == .dark ? UIColor.theme.neutralColor98 : UIColor.theme.neutralColor1
        self.pinCode.textColor =  style == .dark ? UIColor.theme.neutralColor98 : UIColor.theme.neutralColor1
        self.right.setTitleColor(style == . dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor7, for: .disabled)
        self.right.setTitleColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5, for: .normal)
        if style == .dark {
            self.login.setGradient([UIColor(red: 0.2, green: 0.696, blue: 1, alpha: 1),UIColor(red: 0.4, green: 0.47, blue: 1, alpha: 1)],[ CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 1)])
        } else {
            self.login.setGradient([UIColor(red: 0, green: 0.62, blue: 1, alpha: 1),UIColor(red: 0.2, green: 0.293, blue: 1, alpha: 1)], [ CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 1)])
        }
        self.serverConfig.setTitleColor(style == .dark ? UIColor.theme.neutralColor8:UIColor.theme.neutralColor5, for: .normal)
    }
}


extension String {
    public func localized() -> String {
        return DemoLanguage.localValue(key: self)
    }
}

extension UIView {
    
    @discardableResult
    func setGradient(_ colors: [UIColor],_ points: [CGPoint]) -> Self {
        let gradientColors: [CGColor] = colors.map { $0.cgColor }
        let startPoint = points[0]
        let endPoint = points[1]
        let gradientLayer: CAGradientLayer = CAGradientLayer().colors(gradientColors).startPoint(startPoint).endPoint(endPoint).frame(self.bounds).backgroundColor(UIColor.clear.cgColor)
        self.layer.insertSublayer(gradientLayer, at: 0)
        return self
    }
    
}

final class EaseChatProfile:NSObject, EaseProfileProtocol, FFObject {
    
    static func ignoreProperties() -> [String]? {
        ["selected"]
    }
    
    static func customColumnsType() -> [String : String]? {
        nil
    }
    
    static func customColumns() -> [String : String]? {
        nil
    }
    
    static func primaryKeyColumn() -> String {
        "primaryId"
    }
    
    var primaryId: Int = 0

    var id: String = ""
    
    var remark: String = ""
    
    var selected: Bool = false
    
    var nickname: String = ""
    
    var avatarURL: String = ""
    
    public func toJsonObject() -> Dictionary<String, Any>? {
        ["ease_chat_uikit_user_info":["nickname":self.nickname,"avatarURL":self.avatarURL,"userId":self.id,"remark":""]]
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case remark
        case nickname
        case avatarURL
        case selected
    }
    
    override init() {
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        remark = try container.decode(String.self, forKey: .remark)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        selected = try container.decodeIfPresent(Bool.self, forKey: .selected) ?? false
    }
    
}
