//
//  UpYunLivePusher.h
//  DCUniLivePush
//
//  Created by 4Ndf on 2019/5/13.
//  Copyright © 2019 Dcloud. All rights reserved.
//

#import "WXDCLivePusher.h"

NS_ASSUME_NONNULL_BEGIN
@protocol WXUpYunLivePusherProtocol <NSObject>
- (void)listenerEvent:(NSDictionary*)resuest EventType:(NSString*)EventType;
@end

@interface WXUpYunLivePusher : WXDCLivePusher
@property(nonatomic,weak)id<WXUpYunLivePusherProtocol>delegate;
@property (nonatomic, retain) UIView* livePushView;
- (id)initWithOption;
- (void)setWithOption:(NSDictionary*)optionObject;
- (void)preview:(BOOL)ispreview ;
@end

NS_ASSUME_NONNULL_END
