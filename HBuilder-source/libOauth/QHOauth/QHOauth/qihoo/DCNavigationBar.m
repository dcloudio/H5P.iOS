//
//  CustomNavigationBar.m
//  qucsdkFramework
//
//  Created by simaopig on 14-7-11.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "DCNavigationBar.h"
#import <UIKit/UIKit.h>
#import <qucFrameWorkAll/QUCUIConfig.h>

static const CGFloat NavItemDistanceFromTheBottom = 9.0;//导航栏上元素距离底部距离
//navigationBarTitle的字体
#define navBarTitleFont [UIFont boldSystemFontOfSize:18]
//navigationBarRightButton的字体
#define navBarRightBtnFont [UIFont boldSystemFontOfSize:14]

@interface DCNavigationBar()
@property(nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation DCNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = qucDefaultColor;        //初始返回按钮
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _backBtn.titleLabel.font = navBarRightBtnFont;
        _backBtn.backgroundColor =[UIColor clearColor];
        _backBtn.frame = CGRectZero;

        [self addSubview:_backBtn];
        
        //初始右侧按钮
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightBtn.titleLabel.font = navBarRightBtnFont;
        _rightBtn.backgroundColor =[UIColor clearColor];
        _rightBtn.titleLabel.numberOfLines = 1;
        _rightBtn.frame = CGRectZero;
        [_rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:[UIColor grayColor]  forState:UIControlStateHighlighted];
        [self addSubview:_rightBtn];
        
        //设置title 只有一行，颜色为白色、去掉背景色、居中
        _navTitleLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
        _navTitleLabel.font      = navBarTitleFont;
        _navTitleLabel.textColor = [UIColor whiteColor];
        _navTitleLabel.backgroundColor =[UIColor clearColor];
        _navTitleLabel.numberOfLines = 1;
        _navTitleLabel.textAlignment = UITextAlignmentCenter;
        _navTitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_navTitleLabel];
        
        //初始活动指示器
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator.frame = CGRectZero;
        _activityIndicator.hidesWhenStopped = YES;
        [self addSubview:_activityIndicator];
        
        //支持交互
        self.userInteractionEnabled = YES;
      }
    return self;
}


#pragma mark --设置导航title，并同步设置back按钮的frame
-(void) setNavTitle:(NSString *) title
{
    _navTitleLabel.text = title;
    [self setNeedsLayout];
    
    CGSize textSize = [title sizeWithFont:_navTitleLabel.font constrainedToSize:CGSizeMake(180 , 42) lineBreakMode:_navTitleLabel.lineBreakMode];
    CGRect labelFrame = CGRectMake ((qucScreenWidth-textSize.width)/2, self.bounds.size.height-NavItemDistanceFromTheBottom-textSize.height, textSize.width, textSize.height);
    _navTitleLabel.frame = labelFrame;
    

    UIImage *backBtnBgimg = [UIImage imageNamed:@"qucsdkResources.bundle/quc_nav_back_normal"];
    CGSize backBtnBgimgSize = CGSizeMake(50.0,30.0);
    [_backBtn setBackgroundImage:backBtnBgimg forState:UIControlStateNormal];
    [_backBtn setBackgroundImage:[UIImage imageNamed:@"qucsdkResources.bundle/quc_nav_back_pressed"] forState:UIControlStateHighlighted];
    _backBtn.frame = CGRectMake(0.0, _navTitleLabel.frame.origin.y+_navTitleLabel.frame.size.height/2-backBtnBgimgSize.height/2, backBtnBgimgSize.width, backBtnBgimgSize.height);
    
    CGSize  activitySize = [self getActivityIndicatorSize];
    CGFloat activityIndicatorY = _navTitleLabel.frame.origin.y+_navTitleLabel.frame.size.height/2;
    CGFloat activityIndicatorX = (qucScreenWidth - qucPaddingWidth - activitySize.width/2);
    _activityIndicator.frame = CGRectMake(activityIndicatorX,activityIndicatorY, 0, 0);
}


#pragma mark --设置导航title在左侧,
-(void)moveNavLablePox
{
    int nPosX = _backBtn.frame.origin.x + _backBtn.frame.size.width;
    _navTitleLabel.frame = CGRectMake(nPosX, _navTitleLabel.frame.origin.y, _navTitleLabel.frame.size.width, _navTitleLabel.frame.size.height);
}

#pragma mark --设置右侧按钮Title
-(void)setRightBtnTitle:(NSString *)rightBtnTitle
{
    CGSize textSize = [rightBtnTitle sizeWithFont:_rightBtn.titleLabel.font constrainedToSize:CGSizeMake(60,35) lineBreakMode:_rightBtn.titleLabel.lineBreakMode];
    CGRect labelFrame = CGRectMake ( qucScreenWidth-textSize.width - qucPaddingWidth - 20, _navTitleLabel.frame.origin.y+_navTitleLabel.frame.size.height/2-textSize.height/2 - 10, textSize.width + 20, textSize.height + 20);
    [_rightBtn setTitle:rightBtnTitle forState:UIControlStateNormal];
    _rightBtn.frame = labelFrame;
}

#pragma mark --显示返回按钮
-(void)setShowBackbtnAnimated:(BOOL)animated
{
    if(animated) {
        if(!_showBackbtnFlag){
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.3f];
            _backBtn.alpha = 1.0;
            [UIView commitAnimations];
        }
    } else {
        if(!_showBackbtnFlag){
            _backBtn.alpha = 1.0;
        }
    }
    self.showBackbtnFlag = YES;
}

#pragma mark --隐藏返回按钮
-(void)setHideBackbtnAnimated:(BOOL)animated
{
    if(animated) {
        if(_showBackbtnFlag) {
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.3f];
            _backBtn.alpha = 0.0;
            [UIView commitAnimations];
        }
    } else {
        if(_showBackbtnFlag){
            _backBtn.alpha = 0.0;
        }
    }
    self.showBackbtnFlag = NO;
}


#pragma mark --设置返回按钮显示开关，影响其透明度
-(void)setShowBackbtnFlag:(BOOL)_showFlag
{
    _showBackbtnFlag = _showFlag;
    _backBtn.alpha   = _showBackbtnFlag ? 1.0 : 0.0;
}

#pragma mark --显示右侧按钮
-(void)setShowRightBtnAnimated:(BOOL)animated
{
    if(animated) {
        if(!_showRightBtnFlag){
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.3f];
            _rightBtn.alpha = 1.0;
            [UIView commitAnimations];
        }
    } else {
        if(!_showRightBtnFlag){
            _rightBtn.alpha = 1.0;
        }
    }
    _showRightBtnFlag = YES;
}

#pragma mark --隐藏右侧按钮
-(void)setHideRightBtnAnimated:(BOOL)animated
{
    if(animated) {
        if(_showRightBtnFlag) {
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.3f];
            _rightBtn.alpha = 0.0;
            [UIView commitAnimations];
        }
    } else {
        if(_showRightBtnFlag){
            _rightBtn.alpha = 0.0;
        }
    }
    _showRightBtnFlag = NO;
}

-(void)startActivityIndicator
{
    //活动指示器的frame，是其center的frame
    if(_showRightBtnFlag){
        [self setHideBackbtnAnimated:NO];
    }

    [_activityIndicator startAnimating];
}
-(void)stopActivityIndicator
{
    [_activityIndicator stopAnimating];
}

#pragma mark --设置返回按钮显示开关，影响其透明度
-(void)setShowRightBtnFlag:(BOOL)_showFlag
{
    _showRightBtnFlag = _showFlag;
    _rightBtn.alpha   = _showRightBtnFlag ? 1.0 : 0.0;
}

-(CGSize)getActivityIndicatorSize
{
    if(_activityIndicator.activityIndicatorViewStyle == UIActivityIndicatorViewStyleWhiteLarge){
        return CGSizeMake(37.0,37.0);
    } else {
        return CGSizeMake(22.0, 22.0);
    }
}

@end
