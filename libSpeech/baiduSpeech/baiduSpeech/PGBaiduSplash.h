//
//  PGBaiduSplash.h
//  baiduSpeech
//
//  Created by 秦旭力 on 2018/9/21.
//  Copyright © 2018年 EICAPITAN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PGBaiduSplash : UIView

+ (void)showWithBlock:(void(^)(void))block;
+ (void)dismiss;

+ (void)resultVoiceText:(NSString *)text;
+ (void)resultVoiceVolume:(NSInteger)volume;

@end

NS_ASSUME_NONNULL_END
