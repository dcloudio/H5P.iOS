//
//  H5VideoBrightnessView.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/22.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WXH5VideoBrightnessView : UIView
@property (nonatomic, assign) BOOL     isLockScreen;
/** 是否允许横屏,来控制只有竖屏的状态*/
@property (nonatomic, assign) BOOL     isAllowLandscape;
@property (nonatomic, assign) BOOL     isStatusBarHidden;
/** 是否是横屏状态 */
@property (nonatomic, assign) BOOL     isLandscape;
+ (instancetype)sharedView;
- (void)updateLongView:(CGFloat)sound;
@end
