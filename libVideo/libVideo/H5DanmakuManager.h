//
//  H5DanmakuManager.h
//  VideoPlayDemo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface H5DanmakuManager : NSObject
-(instancetype)initWithView:(UIView*)view;
- (void)prepareDanmakus;
- (void)play;
- (void)pause;
- (void)destroy;
- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color;
- (void)sendDanmaku:(NSString*)sender withColor:(UIColor*)color time:(float)time;
@end
