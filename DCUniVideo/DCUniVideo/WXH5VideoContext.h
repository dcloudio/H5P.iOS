//
//  H5VideoContext.h
//  libVideo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WXH5VideoPlayView.h"

@class WXH5VideoContextDelegate;

@protocol WXH5VideoContextDelegate<NSObject>
@optional
//-(void)sendEvent:(NSString*)type toJsCallback:(NSString*)cbId withParams:(NSDictionary*)params inWebview:(NSString*)webId;
-(void)sendEvent:(NSString*)type withParams:(NSDictionary*)params;
- (void)videoPlayerEnterFullScreen;
- (void)videoPlayerExitFullScreen;
@end

@interface WXH5VideoContext :NSObject
@property(nonatomic, strong)NSString *uid;
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)NSString *webviewId;
@property(nonatomic, weak)id<WXH5VideoContextDelegate> delegate;
@property(nonatomic, readonly)WXH5VideoPlayView *videoPlayView;
- (id)initWithFrame:(CGRect)frame;
-(void)creatFrame:(CGRect)frame withSetting:(WXH5VideoPlaySetting*)setting withStyles:(NSDictionary *)styles;

- (void)setHostedView:(UIView*)hostedView;
- (void)setFrame:(CGRect)frame;
- (void)destroy;
- (void)setHidden:(BOOL)isHidden;
@end
