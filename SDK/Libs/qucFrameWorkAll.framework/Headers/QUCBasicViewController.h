//
//  QUCBasicViewController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-19.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QUCToast+UIView.h"
#import "QUCProgressHUD.h"
#import "UINavigationController+GoTo.h"
#import "QUCUIConfig.h"

/**
 *	@brief	用户中心SDK通用ViewController\n
 */
@interface QUCBasicViewController : UIViewController


@property (nonatomic, strong) NSDictionary *qucVcConf;
@property (nonatomic, strong) NSString *navTitle;
@property (nonatomic, assign) BOOL keyboardIsVisible;
@property (nonatomic, strong) NSDictionary *keyboardInfo;
@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, strong) UIView *toastView;

/**
 *	@brief	viewWillAppear会初始化，用于从dict初始化参数
 */
- (void)initProperty;

/**
 *	@brief	viewWillDisappear等视图不可见时清除，用于清空self.dict
 */
- (void)destructProperty;

- (void)addKeyboardObserver;
- (void)removeKeyboardObserver;
- (void)keyboardWillShow:(NSNotification *)notif;
- (void)keyboardWillHide:(NSNotification *)notif;

- (void)addWillEnterForeground;
- (void)removeWillEnterForeground;
- (void)addDidEnterBackground;
- (void)removeDidEnterBackground;
- (void)didEnterBackground:(NSNotification *)notif;

/**
 *	@brief	在窗口中间显示toastView，且3秒消失
 *
 *	@param 	strMsg 	toastView显示内容
 */
- (void)showToastAlertViewWithMsg:(NSString *)strMsg;

/**
 *	@brief	在窗口指定位置 显示toastView
 *
 *	@param 	strMsg 	显示内容
 *	@param 	interval 几秒种消失
 *	@param 	position  toastView显示位置，支持@"top", @"bottom", @"center",
 */
- (void)showToastAlertViewWithMsg:(NSString *)strMsg duration:(CGFloat)interval position:(id)position;

// hxs - add
- (void)showToastAlertViewWithHeadMessage:(NSString *)headMessage linkMessage:(NSString *)linkMessage tailMessage:(NSString *)tailMessage target:(id)target;
- (void)showToastAlertViewWithHeadMessage:(NSString *)headMessage linkMessage:(NSString *)linkMessage tailMessage:(NSString *)tailMessage duration:(CGFloat)duration position:(id)position target:(id)target;

- (UIViewController *)initVcByName:(NSString *)vcName;

@end
