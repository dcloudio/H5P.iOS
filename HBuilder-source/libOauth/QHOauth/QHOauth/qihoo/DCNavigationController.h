//
//  CustomNavigationController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-11.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DCNavigationController;

//可选协议，供业务方重载以实现动画效果
@protocol DCNavigationControllerDelegate <NSObject>
@optional
- (UIViewController *)willPopViewController:(DCNavigationController *)qucNavController animated:(BOOL)animated;
- (void)rightNavBtnClick:(id)sender;
- (void)leftNavBtnClick:(id)sender;

@end
@interface DCNavigationController : UINavigationController<NSObject,UINavigationControllerDelegate>
{
    
}
@property (nonatomic, assign) id<DCNavigationControllerDelegate> customQucNavDelegate;



-(void)goBack:(id) sender;
-(void)setNavTitle:(NSString *) title;
-(void)setShowBackbtnAnimated:(BOOL)animated;
-(void)setHideBackbtnAnimated:(BOOL)animated;
-(void)setHideRightBtnAnimated:(BOOL)animated;
-(void)setShowRightBtnAnimated:(BOOL)animated Title:(NSString *)rightBtnTitle;
-(void)startActivityIndicator;
-(void)stopActivityIndicator;

@end