//
//  H5VideoContext.h
//  libVideo
//
//  Created by DCloud on 2018/5/24.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "H5VideoPlayView.h"

@class H5VideoContextDelegate;

@protocol H5VideoContextDelegate<NSObject>
@optional
-(void)sendEvent:(NSString*)type toJsCallback:(NSString*)cbId withParams:(NSDictionary*)params inWebview:(NSString*)webId;
@end

@interface H5VideoContext :NSObject
@property(nonatomic, strong)NSString *uid;
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)NSString *webviewId;
@property(nonatomic, weak)id<H5VideoContextDelegate> delegate;
@property(nonatomic, readonly)H5VideoPlayView *videoPlayView;
- (id)initWithFrame:(CGRect)frame withSetting:(H5VideoPlaySetting*)setting withStyles:(NSDictionary*)styles;
- (void)setHostedView:(UIView*)hostedView;
- (void)setListener:(NSString*)cbId forEvt:(NSString*)evt forWebviewId:(NSString*)webviewId;
- (void)setFrame:(CGRect)frame;
- (void)destroy;
@end
