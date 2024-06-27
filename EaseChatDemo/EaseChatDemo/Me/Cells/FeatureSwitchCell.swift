//
//  FeatureSwitchCell.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/3/13.
//

import UIKit
import EaseChatUIKit

final class FeatureSwitchCell: UITableViewCell {

    lazy var featureName: UILabel = {
        UILabel(frame: CGRect(x: 16, y: 16, width: self.contentView.frame.width-73, height: 22)).font(UIFont.theme.labelLarge)
    }()
    
    lazy var featureSwitch: UISwitch = {
        UISwitch(frame: CGRect(x: self.contentView.frame.width-63, y: 11.5, width: 51, height: 31))
    }()

    lazy var detailContainer: UIView = {
        UIView(frame: CGRect(x: 0, y: self.featureName.frame.maxY+20, width: self.frame.width, height: 26))
    }()
    
    lazy var featureDetail: UILabel = {
        UILabel(frame: CGRect(x: 16, y: self.featureName.frame.maxY+24, width: self.contentView.frame.width-32, height: 16)).font(UIFont.theme.bodyMedium)
    }()
    
    lazy var separatorLine: UIView = {
        UIView(frame: CGRect(x: 16, y: self.contentView.frame.height-0.5, width: self.contentView.frame.width-16, height: 0.5))
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.addSubViews([self.featureName,self.featureSwitch,self.detailContainer,self.featureDetail,self.separatorLine])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.featureName.frame = CGRect(x: 16, y: 16, width: self.contentView.frame.width-73, height: 22)
        self.detailContainer.frame =  CGRect(x: 0, y: self.featureName.frame.maxY+20, width: self.frame.width, height: 26)
        self.featureSwitch.frame = CGRect(x: self.contentView.frame.width-63, y: 11.5, width: 51, height: 31)
        self.featureDetail.frame = CGRect(x: 16, y: self.featureName.frame.maxY+24, width: self.contentView.frame.width-32, height: 16)
        self.separatorLine.frame = CGRect(x: 16, y: self.featureName.frame.maxY+20, width: self.frame.width-16, height: 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeatureSwitchCell: ThemeSwitchProtocol {
    func switchTheme(style: ThemeStyle) {
        self.featureName.textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        self.detailContainer.backgroundColor = style == .dark ? UIColor.theme.neutralColor0:UIColor.theme.neutralColor95
        self.featureDetail.textColor(style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5)
        self.separatorLine.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor9
        self.featureSwitch.onTintColor = style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
    }
}
