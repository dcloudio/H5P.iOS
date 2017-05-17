/*
 *------------------------------------------------------------------
 *  pandora/feature/message/pg_message.h
 *  Description:
 *      消息插件头文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-1-8 创建文件
 *------------------------------------------------------------------
 */

#import <MessageUI/MessageUI.h>
#import "PGPlugin.h"
#import "PGMethod.h"

@class PGMessaging;

typedef NS_ENUM(NSInteger, PGMessageType) {
    PGMessageTypeSMS = 1, // SMS
    PGMessageTypeMMS = 2, // MMS
    PGMessageTypeMail = 3 // EMAIL
};

typedef NS_ENUM(NSInteger, PGMessageBodyType) {
    PGMessageBodyTypeHTML = 1, // HTML
    PGMessageBodyTypeTEXT = 2, // TEXT
};

/*
 **@消息封装
 */
@class PGMessage;
@protocol PGMessageDeleage <NSObject>
@optional
-(void)sendEnd:(PGMessage*)message;
@end

@interface PGMessage : NSObject
<MFMessageComposeViewControllerDelegate,
MFMailComposeViewControllerDelegate>
{
    @private
    NSMutableArray *_to;
    NSMutableArray *_cc;
    NSMutableArray *_bcc;
    NSMutableString *_subject;
    NSMutableString *_body;
    
    NSMutableArray *_attachemnt;
}

@property(nonatomic, retain)NSArray *to;
@property(nonatomic, retain)NSArray *cc;
@property(nonatomic, retain)NSArray *bcc;
@property(nonatomic, retain)NSString *subject;
@property(nonatomic, retain)NSString *body;

@property(nonatomic, assign)PGMessageBodyType bodyType;
@property(nonatomic, assign)BOOL silent;
@property(nonatomic, readonly)NSArray *attachment;

@property(nonatomic, retain)NSString *UUID;
@property(nonatomic, assign)PGMessageType type;
@property(nonatomic, assign)PGMessaging *jsBrige;
@property(nonatomic, assign)id<PGMessageDeleage> delegate;

+(PGMessage*)messageWithJSON:(NSMutableDictionary*)json;
-(void)send;
-(UIViewController*)pickRootViewController;

@end

/*
 **@信息管理模块
 */
@interface PGMessaging : PGPlugin<PGMessageDeleage>
{
    NSMutableArray *_messageDict;
}
@property (readwrite, assign) BOOL hasPendingOperation;
-(void)sendMessage:(PGMethod*)command;
-(void)sendEnd:(PGMessage*)message;
-(void)result:(PDRCommandStatus)resultCode
      message:(NSString*)message
   callBackId:(NSString*)callbackId;
@end