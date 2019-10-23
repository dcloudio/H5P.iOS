//
//  DCViewControllerShowHUDProgress.h
//  DemoProject
//
//  Created by nearwmy on 2018/6/19.
//  Copyright © 2018年 nearwmy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCUIViewControllerHUD : UIViewController
@property (nonatomic) UIButton *progressHUD;
@property (nonatomic) UIView *HUDContainer;
@property (nonatomic) UIActivityIndicatorView *HUDIndicatorView;
@property (nonatomic) UILabel *HUDLabel;

- (void)showProgressHUD;
- (void)hideProgressHUD;
- (void)layoutProgressHUD;
@end
