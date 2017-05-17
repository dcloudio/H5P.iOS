//
//  CustomNavigationBar.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-11.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCNavigationBar : UIImageView

@property(nonatomic,strong) UILabel  *navTitleLabel;
@property(nonatomic,strong) UIButton *backBtn;
@property(nonatomic,strong) UIButton *rightBtn;
@property(nonatomic,assign) BOOL showBackbtnFlag;
@property(nonatomic,assign) BOOL showRightBtnFlag;


-(void)setNavTitle:(NSString *) title;
-(void)setShowBackbtnAnimated:(BOOL)animated;
-(void)setHideBackbtnAnimated:(BOOL)animated;
-(void)setShowRightBtnAnimated:(BOOL)animated;
-(void)setHideRightBtnAnimated:(BOOL)animated;
-(void)setRightBtnTitle:(NSString *)rightBtnTitle;
-(void)startActivityIndicator;
-(void)stopActivityIndicator;
-(void)moveNavLablePox;
@end
