/*
 *------------------------------------------------------------------
 *  pandora/PGShare.h
 *  Description:
 *      上传插件头文件定义
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-03-22 创建文件
 *------------------------------------------------------------------
 */
#import "PGPlugin.h"
#import "PGMethod.h"

#import "PGShareControl.h"

typedef NS_ENUM(NSInteger, PGShareError) {
    PGShareErrorNO = 0, //ok
    PGShareErrorOther = 64000, //
    PGShareErrorUserCancel = 64001, //用户取消分享操作
    PGShareErrorNotAuthorize = 64003, //用户未进行授权认证
    PGShareErrorRepeateAuthReq = 640014, //
    PGShareErrorBadParam = 640015, //
    PGShareErrorUserNotExists = 640016,
    PGShareErrorAuthorizeUserCancel = 640017, //
    PGShareErrorShareNotSupport = 640018,
    PGShareErrorShareInvalidClient = 640019
};

typedef NS_ENUM(NSInteger, PGShareMessageScene) {
    PGShareMessageSceneTimeline,
    PGShareMessageSceneSession,
    PGShareMessageSceneFavorite
};

typedef NS_ENUM(NSInteger, PGShareMessageInterface) {
    PGShareMessageInterfaceAuto,//自动选择，如果已经安装微博客户端则采用编辑界面进行分享，否则采用第二种无界面分享；
    PGShareMessageInterfaceSlient,//静默分享，采用第二种无界面模式进行分享；
    PGShareMessageInterfaceEditable//进入编辑界面，如果当前未安装微博客户端则触发错误回调
};

@class PGJSRequest;

@interface PGShareMessage : NSObject
@property(nonatomic, copy)NSString *msgType;
@property(nonatomic, copy)NSString *title;
@property(nonatomic, copy)NSString *content;
@property(nonatomic, copy)NSArray *thumbs;
@property(nonatomic, copy)NSArray *pictures;
@property(nonatomic, copy)NSString* media;
@property(nonatomic, copy)NSString *sendPict;
@property(nonatomic, copy)NSString *sendThumb;
@property(nonatomic, copy)NSString *latitude;
@property(nonatomic, copy)NSString *longitude;
@property(nonatomic, copy)NSString *href;
@property(nonatomic, copy)NSDictionary* miniProgram;
@property(nonatomic, assign)PGShareMessageScene scene;
@property(nonatomic, assign)PGShareMessageInterface interface;
+ (PGShareMessage*)msgWithDict:(NSDictionary*)dict;

@end

@protocol PGShare <NSObject>
@required
- (BOOL)logOut;
- (NSString*)getToken;
- (BOOL)cancelPrevAuthorize;
- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(id)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback;
- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback;
- (PGAuthorizeView*)getAuthorizeControl;
- (void)doInit;
@end

@interface PGShare : PGPlugin<PGShare> {
    //认证请求
    PGJSRequest *_authorizeReq;
    NSMutableArray *_shareServices;
    //发送队列
    NSMutableArray *_sendPeer;
   // BOOL _sendHasPendingOperation;
}
@property(nonatomic, copy)NSString* type;
@property(nonatomic, assign)BOOL authenticated;
@property(nonatomic, assign)BOOL nativeClient;
@property(nonatomic, copy)NSString *accessToken;
@property(nonatomic, copy)NSString *note;
@property(nonatomic, copy)NSString *commonPath;
- (void)doInit;
- (NSString*)errorMsgWithCode:(int)errorCode;
- (void)authorize:(PGMethod*)command;
- (void)forbid:(PGMethod*)command;
- (void)send:(PGMethod*)command;
- (BOOL)launchMiniProgram:(PGMethod*)command;
- (NSDictionary*)JSDict;
@end
