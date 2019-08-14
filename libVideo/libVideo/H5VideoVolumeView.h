//
//  H5VideoVolumeView.h
//  libVideo
//
//  Created by 4Ndf on 2019/8/9.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface H5VideoVolumeView : UIView
@property (nonatomic, assign) BOOL     isLockScreen;
/** 是否允许横屏,来控制只有竖屏的状态*/
@property (nonatomic, assign) BOOL     isAllowLandscape;
@property (nonatomic, assign) BOOL     isStatusBarHidden;
/** 是否是横屏状态 */
@property (nonatomic, assign) BOOL     isLandscape;
@property (nonatomic,assign)CGFloat volume;
+ (instancetype)sharedView;
- (void)updateLongView:(CGFloat)sound;
@end

NS_ASSUME_NONNULL_END
