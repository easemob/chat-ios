//
//  MeMenuCell.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/5.
//

import UIKit
import EaseChatUIKit

final class MeMenuCell: UITableViewCell {
    
    lazy var icon: UIImageView = {
        UIImageView(frame: CGRect(x: 16, y: 13, width: self.contentView.frame.height-26, height: self.contentView.frame.height-26))
    }()
    
    lazy var content: UILabel = {
        UILabel(frame: CGRect(x: self.icon.frame.maxX+8, y: 16, width: (self.frame.width-32)/2.0, height: 22)).font(UIFont.theme.labelLarge)
    }()
    
    lazy var detail: UILabel = {
        UILabel(frame: CGRect(x: self.frame.width-156, y: 18, width: 120, height: 18)).font(UIFont.theme.labelMedium).textAlignment(.right)
    }()
    
    public private(set) lazy var separatorLine: UIView = {
        UIView(frame: CGRect(x: self.textLabel?.frame.minX ?? 16, y: self.contentView.frame.height - 0.5, width: self.frame.width, height: 0.5))
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.textLabel?.font(UIFont.theme.labelLarge)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.addSubViews([self.icon,self.content,self.detail,self.separatorLine])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.icon.frame = CGRect(x: 16, y: 13, width: self.contentView.frame.height-26, height: self.contentView.frame.height-26)
        self.content.frame = CGRect(x: self.icon.frame.maxX+8, y: 16, width: (self.frame.width-32)/2.0, height: 22)
        self.detail.frame = CGRect(x: self.frame.width-156, y: 18, width: 120, height: 18)
        self.separatorLine.frame = CGRect(x: self.content.frame.minX, y: self.contentView.frame.height - 0.5, width: self.frame.width, height: 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension MeMenuCell: ThemeSwitchProtocol {

    func switchTheme(style: ThemeStyle) {
        self.textLabel?.textColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5)
        self.content.textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        self.detail.textColor(style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5)
        self.accessoryView?.tintColor = style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor3
        self.accessoryView?.subviews.first?.tintColor = style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor3
        
        self.separatorLine.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor9
    }
}
