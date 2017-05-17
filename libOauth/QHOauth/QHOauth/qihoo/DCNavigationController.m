//
//  CustomNavigationController.m
//  qucsdkFramework
//
//  Created by simaopig on 14-7-11.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <qucFrameWorkAll/QUCUIConfig.h>
#import "DCNavigationController.h"
#import "DCNavigationBar.h"


/*动画时间*/
static const CGFloat NavPushAnimated   = 0.35;//导航push view的动画执行时间 seconds
static const CGFloat NavPopAnimated    = 0.35;//导航pop view的动画执行时间 seconds
static const CGFloat NavBarOriginY     = 20.0;//导航栏的Y坐标
static const CGFloat NavBarOriginYIos7 = 0.0;//IOS7下的导航栏Y坐标
static const CGFloat NavBarHeight      = 44.0;//系统默认导航高度
static const CGFloat NavBarHeightIos7  = 64.0;//IOS7下的导航栏高度

#define IOS7_OR_LATER [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0

#define NAV_BAR_FRAME  IOS7_OR_LATER ? CGRectMake(0.0, NavBarOriginYIos7, qucScreenWidth, NavBarHeightIos7) : \
CGRectMake(0.0, NavBarOriginY, qucScreenWidth, NavBarHeight)

@interface DCNavigationController ()

@property   (nonatomic,strong)   DCNavigationBar *customNavBar;

@end

@implementation DCNavigationController
@synthesize customQucNavDelegate = _customQucNavDelegate;
@synthesize customNavBar = _customNavBar;



- (id)initWithRootViewController:(UIViewController *)rootViewController{
    
    self = [super initWithRootViewController:rootViewController];
    if(self){
        self.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _customNavBar = [[DCNavigationBar alloc] initWithFrame:NAV_BAR_FRAME];
    self.navigationBar.userInteractionEnabled = NO;
    self.navigationBar.alpha = 0.0001;
    [_customNavBar.backBtn addTarget:self action:@selector(leftBtnTouchDown:) forControlEvents:UIControlEventTouchUpInside];
    [_customNavBar.rightBtn addTarget:self action:@selector(rightBtnTouchDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_customNavBar];
    _customNavBar.showBackbtnFlag = NO;
    _customNavBar.showRightBtnFlag = NO;
}

#pragma mark --点击返回按钮，则将当前view 弹出
-(void) goBack:(id) sender
{
    if([[self viewControllers] count] <= 1)
    {
        if ([_customQucNavDelegate respondsToSelector:@selector(leftNavBtnClick:)]) {
            [_customQucNavDelegate leftNavBtnClick:sender];
        }
    }
    else if ([[self viewControllers] count] <= 2) {
        [self popViewControllerAnimated:NO];
    } else {
        [self popViewControllerAnimated:YES];
    }
}

- (void)leftBtnTouchDown:(id) sender
{
    //先将未到时间执行前的任务取消。
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(leftBtnOnClick:) object:sender];
    [self performSelector:@selector(leftBtnOnClick:) withObject:sender afterDelay:0.2f];
}

#pragma mark --点击左侧按钮
-(void) leftBtnOnClick:(id) sender
{
    [self goBack:sender];
}

- (void)rightBtnTouchDown:(id) sender
{
    //先将未到时间执行前的任务取消。
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(rightBtnOnClick:) object:sender];
    [self performSelector:@selector(rightBtnOnClick:) withObject:sender afterDelay:0.2f];
}

#pragma mark --点击右侧按钮
-(void) rightBtnOnClick:(id) sender
{
    if ([_customQucNavDelegate respondsToSelector:@selector(rightNavBtnClick:)]) {
        [_customQucNavDelegate rightNavBtnClick:sender];
    }
    return;
}

#pragma mark --覆盖父类方法，仅支持竖屏
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark --设置导航标题
- (void)setNavTitle:(NSString *)title{
    [_customNavBar setNavTitle:title];
}

#pragma mark --显示返回按钮
-(void)setShowBackbtnAnimated:(BOOL)animated
{
    [_customNavBar setShowBackbtnAnimated:animated];
}

#pragma mark --隐藏返回按钮
-(void)setHideBackbtnAnimated:(BOOL)animated
{
    [_customNavBar setHideBackbtnAnimated:animated];
}

#pragma mark --隐藏右侧按钮
-(void)setHideRightBtnAnimated:(BOOL)animated
{
    [_customNavBar setHideRightBtnAnimated:animated];
}

#pragma mark --显示右侧按钮
-(void)setShowRightBtnAnimated:(BOOL)animated Title:(NSString *)rightBtnTitle
{
    [_customNavBar setRightBtnTitle:rightBtnTitle];
    [_customNavBar setShowRightBtnAnimated:animated];
}

#pragma mark --start活动指示器
-(void)startActivityIndicator
{
    [_customNavBar startActivityIndicator];
}

#pragma mark --stop活动指示器
-(void)stopActivityIndicator
{
    [_customNavBar stopActivityIndicator];
}

#pragma mark --载入子视图
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
   
    [self setShowBackbtnAnimated:animated];
    if(!animated){
        [super pushViewController:viewController animated:NO];
    } else {
        CATransition *animation = [CATransition animation];
        [animation setDuration:NavPushAnimated];
        [animation setType:kCATransitionPush]; //淡入淡出
        [animation setSubtype:kCATransitionFromRight];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        [super pushViewController:viewController animated:NO];
        [self.view.layer addAnimation:animation forKey:nil];
    }
}

#pragma mark --弹出子视图
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    NSArray *vcs = [self viewControllers];
    if([vcs count]<=1){
        [self setHideBackbtnAnimated:YES];
        [self setHideRightBtnAnimated:YES];
    }
    
    UIViewController *controller;
    
    if ([_customQucNavDelegate respondsToSelector:@selector(willPopViewController:animated:)]) {
        controller = [_customQucNavDelegate willPopViewController:self animated:animated];
    } else {
        if(!animated){
            controller = [super popViewControllerAnimated:NO];
        } else {
            CATransition *animation = [CATransition animation];
            [animation setDuration:NavPopAnimated];
            [animation setType:kCATransitionPush]; //淡入淡出
            [animation setSubtype:kCATransitionFromRight];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
            controller = [super popViewControllerAnimated:NO];
            [self.view.layer addAnimation:animation forKey:nil];
        }
    }
    
    return controller;
}

#pragma mark --弹出指定子视图
- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{    
    NSArray *vcs = nil;
    NSArray *tempVcs = [self viewControllers];
    if(!animated){
        vcs = [super popToViewController:viewController animated:NO];
    } else {
        CATransition *animation = [CATransition animation];
        [animation setDuration:NavPopAnimated];
        [animation setType:kCATransitionPush]; //淡入淡出
        [animation setSubtype:kCATransitionFromRight];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        vcs = [super popToViewController:viewController animated:NO];
        [self.view.layer addAnimation:animation forKey:nil];
    }

    if([tempVcs count]<=2){
        [self setHideBackbtnAnimated:YES];
        [self setHideRightBtnAnimated:YES];
    }
    return vcs;
}

@end
