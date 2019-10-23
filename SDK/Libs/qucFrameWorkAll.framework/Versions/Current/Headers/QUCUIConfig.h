//
//  QUCUIConfig.h
//  qucsdkFramework
//
//  Created by xuruiqiao on 14-7-3.
//  Copyright (c) 2014年 Qihoo.360. All rights resrved.
//  调用QUCConfig类，通过qucsdkResources.bundle中的QUCConfig.plist读取配置


#import "QUCConfig.h"

/*设备属性屏幕宽高*/
#define qucScreenWidth  ([UIScreen mainScreen].bounds.size.width)
#define qucScreenHeight ([UIScreen mainScreen].bounds.size.height)


/*控件布局*/
//控件默认两边留白大小
#define qucPaddingWidth [[QUCConfig getInstance] getLayout:@"qucPaddingWidth"]
//每行控件所占最大宽度（屏幕宽度-2*留白宽度）
#define qucEachLineWidth (qucScreenWidth - qucPaddingWidth*2)
//每行控件之间水平间隔（“密码框”与“显示、隐藏密码按钮“、”校验码“与”发送短信按钮“）
#define qucEachLineHorizontalInterval [[QUCConfig getInstance] getLayout:@"qucEachLineHorizontalInterval"]
//每行两个控件情况下，左侧控件的宽度占全部可用宽度的2/3
#define qucEachLineSubviewLeftWidth ((qucEachLineWidth - qucEachLineHorizontalInterval) / 3 * 2)
//每行两个控件情况下，右侧控件的宽度占全部可用宽度的1/3
#define qucEachLineSubviewRightWidth (qucEachLineSubviewLeftWidth / 2 )
//第一控件距离导航栏的顶部留白（即第一个控件的y轴坐标）
#define qucPaddingTopHeight [[QUCConfig getInstance] getLayout:@"qucPaddingTopHeight"]
//控件之间的小垂直间隔
#define qucLittleVerticalInterval [[QUCConfig getInstance] getLayout:@"qucLittleVerticalInterval"]
//控件之间的中垂直间隔
#define qucMiddleVerticalInterval [[QUCConfig getInstance] getLayout:@"qucMiddleVerticalInterval"]
//控件之间的大垂直间隔
#define qucBigVerticalInterval [[QUCConfig getInstance] getLayout:@"qucBigVerticalInterval"]
//小控件的高度（链接，label）
#define qucLittleHeight [[QUCConfig getInstance] getLayout:@"qucLittleHeight"]
//大控件的高度(button,textField)
#define qucBigHeight [[QUCConfig getInstance] getLayout:@"qucBigHeight"]
//alertView的Y轴
#define qucAlertPaddingTopHeight [[QUCConfig getInstance] getLayout:@"qucAlertPaddingTopHeight"]
//alertView的高度
#define qucAlertHeight [[QUCConfig getInstance] getLayout:@"qucAlertHeight"]
//alertView的宽度，与控件的最大宽度相同
#define qucAlertWidth  qucEachLineWidth
//进度条Level为UIWindowLevelAlert+这个值!
#define qucProgressWindowLevel [[QUCConfig getInstance] getLayout:@"qucProgressWindowLevel"]

/*颜色，默认颜色对应16进制：http://foobarpig.com/iphone/uicolor-cheatsheet-color-list-conversion-from-and-to-rgb-values.html*/
//默认的风格色（绿色）
#define qucDefaultColor [[QUCConfig getInstance] getColor:@"qucDefaultColor"]
//默认的链接label颜色
#define qucUnderLineBtnTitleColor [[QUCConfig getInstance] getColor:@"qucUnderLineBtnTitleColor"]
//alert框中手机和邮箱的颜色
#define qucAlertViewEmphasesColor [[QUCConfig getInstance] getColor:@"qucAlertViewEmphasesColor"]
//默认的背景色
#define qucDefaultBackGroundColor [[QUCConfig getInstance] getColor:@"qucDefaultBackGroundColor"]
//白色按钮字体颜色（正常状态）
#define qucWhiteBtnTitleColorNormal [[QUCConfig getInstance] getColor:@"qucWhiteBtnTitleColorNormal"]
//白色按钮的字体颜色（高亮状态）
#define qucWhiteBtnTitleColorHighLight [[QUCConfig getInstance] getColor:@"qucWhiteBtnTitleColorHighLight"]
//普通label的字体颜色
#define qucNormalLabelTitleColor [[QUCConfig getInstance] getColor:@"qucNormalLabelTitleColor"]
//浅色label（提示）字体颜色
#define qucRemindLabelTitleColor [[QUCConfig getInstance] getColor:@"qucRemindLabelTitleColor"]
//显示密码字体颜色
#define qucShowPwdBtnTitleColor [[QUCConfig getInstance] getColor:@"qucShowPwdBtnTitleColor"]
//checkbox字体颜色
#define qucCheckboxTitleColor [[QUCConfig getInstance] getColor:@"qucCheckboxTitleColor"]

// regionsView title深灰
#define qucRegionsViewTitleColor [[QUCConfig getInstance] getColor:@"qucRegionsViewTitleColor"]
// regionsView region浅灰
#define qucRegionsViewRegionColor [[QUCConfig getInstance] getColor:@"qucRegionsViewRegionColor"]
// regionCell text深灰
#define qucRegionCellLeftColor [[QUCConfig getInstance] getColor:@"qucRegionCellLeftColor"]
#define qucRegionCellRightColor [[QUCConfig getInstance] getColor:@"qucRegionCellRightColor"]


/*字体、字号*/
//大按钮（提交）的字体
#define qucButtonTitleFont [[QUCConfig getInstance] getFont:@"qucButtonTitleFont"]
//链接的字体
#define qucLinkTitleFont [[QUCConfig getInstance] getFont:@"qucLinkTitleFont"]
//显示密码按钮的字体
#define qucShowPwdBtnTitleFont [[QUCConfig getInstance] getFont:@"qucShowPwdBtnTitleFont"]
//获取验证码按钮的字体
#define qucSendSmsButtonTitleFont [[QUCConfig getInstance] getFont:@"qucSendSmsButtonTitleFont"]
//qucTextField中的字体
#define qucTextFieldFont [[QUCConfig getInstance] getFont:@"qucTextFieldFont"]
//非链接的label的字体
#define qucLabelFieldFont [[QUCConfig getInstance] getFont:@"qucLabelFieldFont"]
//checkbox字体
#define qucCheckboxTitleFont [[QUCConfig getInstance] getFont:@"qucCheckboxTitleFont"]

// regionsView title
#define qucRegionsViewTitleFont [[QUCConfig getInstance] getFont:@"qucRegionsViewTitleFont"]
// regionsView region
#define qucRegionsViewRegionFont [[QUCConfig getInstance] getFont:@"qucRegionsViewRegionFont"]
// regionCell text
#define qucRegionCellLeftFont [[QUCConfig getInstance] getFont:@"qucRegionCellLeftFont"]
#define qucRegionCellRightFont [[QUCConfig getInstance] getFont:@"qucRegionCellRightFont"]


/*控件背景图*/
//提交按钮的背景图
#define qucSubmitBtnBackgroundImageForNormal [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
#define qucSubmitBtnBackgroundImageForPressed [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_press.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
//显示密码，获得短信校验码按钮的背景图
#define qucWhiteBtnBackgroundImageForNormal [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_white.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
#define qucWhiteBtnBackgroundImageForPressed [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_white_pressed.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
//alertView中otherButton的背景图
#define qucDialogOtherButtonImageForNormal [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
#define qucDialogOtherButtonImageForPressed [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_press.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
//alertView中cancelButton的背景图
#define qucDialogCancelButtonImageForNormal [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_white.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
#define qucDialogCancelButtonImageForPressed [[UIImage imageNamed:@"qucsdkResources.bundle/quc_button_white_pressed.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0]
//alertView中destructiveButton的背景图
#define qucDialogDestruntiveBtnImageForNormal [UIImage imageNamed:@"qucsdkResources.bundle/quc_dialog_close.png"]
#define qucDialogDestruntiveBtnImageForPressed [UIImage imageNamed:@"qucsdkResources.bundle/quc_dialog_close_pressed.png"]
//checkBox中的勾选图片
#define qucCheckBoxImageNormal  [UIImage imageNamed:@"qucsdkResources.bundle/quc_checkbox_unselected.png"]
#define qucCheckBoxImageClicked [UIImage imageNamed:@"qucsdkResources.bundle/quc_checkbox_click.png"]
//suggest cell默认背景图
#define qucSuggestCellDefBgImg [UIImage imageNamed:@"qucsdkResources.bundle/quc_suggest_bg.png"]
#define qucSuggestCellSelectedBgImg [UIImage imageNamed:@"qucsdkResources.bundle/quc_suggest_selected.png"]
//progress hud
#define qucProgressSuccessImg [UIImage imageNamed:@"qucsdkResources.bundle/quc_progress_hud_success.png"]
#define qucProgressErrorImg [UIImage imageNamed:@"qucsdkResources.bundle/quc_progress_hud_error.png"]

// arrow image - hxs
#define qucRegionsArrowImage [UIImage imageNamed:@"qucsdkResources.bundle/quc_image_right_arrow.png"];