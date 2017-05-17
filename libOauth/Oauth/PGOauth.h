/*
 *------------------------------------------------------------------
 *  pandora/PGOauth.h
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

typedef NS_ENUM(NSInteger, PGOauthError) {
    PGOauthErrorNeedLogin = -1001,
    PGOauthErrorNotInstall = -1002,
    PGOauthErrorNotSupportSSOLogin = -1003,
    PGOauthErrorNotInstall1 = PGPluginErrorNext
};

@protocol PGOauth <NSObject>
-(NSString*)getAesKey;
-(NSString*)getSaveFilePath;
-(NSDictionary*)getSaveDict;

- (NSDictionary*)JSDict;
- (void)handleOpenURL:(NSNotification*)notification;
@end

@interface PGOauth : PGPlugin<PGOauth> {
}

@property(nonatomic, retain)NSString *identify;
@property(nonatomic, retain)NSString *note;
@property(nonatomic, assign)BOOL needToSaveFile;
@property(nonatomic, retain)NSString *mscope;

- (void)login:(NSString*)cbId withParams:(NSDictionary*)params;
- (void)logout:(NSString*)cbId;
- (void)getUserInfo:(NSString*)cbId;
- (void)addPhoneNumber:(NSString*)cbId;
- (NSString*)errorMsgWithCode:(int)errorCode;
- (void)initalize;
- (NSDictionary*)JSDict;

- (NSDictionary*)decodeSaveDict;
- (void)handleOpenURL:(NSNotification*)notification;
-(NSString*)getAesKey;
-(NSString*)getSaveFilePath;
-(NSDictionary*)getSaveDict;

@end
