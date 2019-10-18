/*
 *------------------------------------------------------------------
 *  pandora/feature/PGShare
 *  Description:
 *    上传插件实现定义
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
#import "PGWXPay.h"
#import "PDRCore.h"
#import "DC_JSON.h"

@implementation PGWXPay

@synthesize callBackID;
@synthesize isRevOpenUrl;
@synthesize urlScheme;
@synthesize universalLink;
- (id)init {
    if ( self = [super init] ) {
        self.type = @"wxpay";
        self.description = @"微信";
        self.sdkErrorURL = @"https://pay.weixin.qq.com/wiki/doc/api/app.php?chapter=8_5";
        
        NSArray *urlSchemes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        for ( NSDictionary *shemeItem in urlSchemes ) {
            NSString *URLIdentifier = [shemeItem objectForKey:@"CFBundleURLName"];
            if ( NSOrderedSame == [@"weixin" caseInsensitiveCompare:URLIdentifier] ) {
                NSArray *appids = [shemeItem objectForKey:@"CFBundleURLSchemes"];
                self.urlScheme = [appids objectAtIndex:0];
                break;
            }
        }
        if ( self.urlScheme ) {
            self.universalLink = [self getUniversalLink];
            [WXApi registerApp:self.urlScheme universalLink:self.universalLink];
            self.serviceReady = [WXApi isWXAppInstalled];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleOpenURL:)
                                                     name:PDRCoreOpenUrlNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUniversalLinks:)
                                                     name:PDRCoreOpenUniversalLinksNotification
                                                   object:nil];
    }
    return self;
}

- (void)request:(PGMethod*)command {
    NSString *cbID = [command.arguments objectAtIndex:2];
    NSDictionary *arg1 = [command.arguments objectAtIndex:1];

//    if ( self.callBackID ) {
//        [self toErrorCallback:cbID withCode:PGPluginErrorBusy];
//        return;
//    }

    if ( [arg1 isKindOfClass:[NSString class]] ) {
        arg1 = [(NSString*)arg1 JSONValue];
    }
    
    if ( [arg1 isKindOfClass:[NSDictionary class]] ) {
        NSString *openid = [arg1 objectForKey:@"appid"];
        NSString *partnerId = [arg1 objectForKey:@"partnerid"];
        NSString *prepayId = [arg1 objectForKey:@"prepayid"];
        NSString *package = [arg1 objectForKey:@"package"];
        NSString *nonceStr = [arg1 objectForKey:@"noncestr"];
        UInt32 timeStamp = 0;
        NSString *sign = [arg1 objectForKey:@"sign"];
        
        NSNumber *timeStampJS = [arg1 objectForKey:@"timestamp"];
        if ( [timeStampJS isKindOfClass:[NSString class]]
            || [timeStampJS isKindOfClass:[NSNumber class]]){
            timeStamp = [timeStampJS intValue];
        }
        if ( [partnerId isKindOfClass:[NSString class]]
            && [prepayId isKindOfClass:[NSString class]]
            && [package isKindOfClass:[NSString class]]
            && [nonceStr isKindOfClass:[NSString class]]
            && [sign isKindOfClass:[NSString class]]) {
            
            if ( nil == self.urlScheme ) {
                [self toErrorCallback:cbID withCode:PGPluginErrorConfig];
                return;
            }
            
            if ( NSOrderedSame != [openid caseInsensitiveCompare:self.urlScheme] ) {
                [self toErrorCallback:cbID withCode:PGWXPayAppidNotSame];
                return;
            }
            
            if ( ![WXApi isWXAppInstalled] ) {
                [self toErrorCallback:cbID withCode:PGPluginErrorNoInstall];
                return;
            }
            PayReq *request = [[PayReq alloc] init];
            request.openID = openid;
            request.partnerId = partnerId;
            request.prepayId= prepayId;
            request.package = package;
            request.nonceStr= nonceStr;
            request.timeStamp= timeStamp;
            request.sign= sign;
            [WXApi sendReq:request completion:^(BOOL success) {
                if ( success ) {
                    self.isRevOpenUrl = true;
                    self.callBackID = [cbID isKindOfClass:[NSString class]]?cbID:nil;
                } else {
                    [self toErrorCallback:cbID withCode:PGPluginErrorInvalidArgument];
                }
            }];
        }
    }
}

- (void)installService {
    NSString *installUrl = [WXApi getWXAppInstallUrl];
    if ( installUrl ) {
        NSURL *url = [NSURL URLWithString:installUrl];
        if ( url ) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (NSDictionary*)JSDict {
    // 重新检查当前service可用性
    if ( self.urlScheme ) {
        [WXApi registerApp:self.urlScheme universalLink:self.universalLink];
        self.serviceReady = [WXApi isWXAppInstalled];
    }
    return [super JSDict];
}

-(void) onResp:(BaseResp*)resp {
   // int errorCode = PGPayErrorOther;
    if([resp isKindOfClass:[PayResp class]]) {
        PayResp *payResponse = (PayResp*)resp;
        if ( WXSuccess == payResponse.errCode ) {
//            NSDictionary *dict = [NSDictionary
//                                  dictionaryWithObjectsAndKeys:self.type, @"channel",
//                                  @"", @"tradno",
//                                  payResponse.returnKey ? payResponse.returnKey : @"", @"description",
//                                  @"" , @"signature",
//                                  @"", @"url", nil];
            NSDictionary *dict = [NSDictionary
                                  dictionaryWithObjectsAndKeys:self.type, @"channel",
                                  payResponse.returnKey ? payResponse.returnKey : @"", @"rawdata", nil];
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
            [self toCallback:self.callBackID withReslut:[result toJSONString]];
        } else {
            [self toErrorCallback:self.callBackID withSDKError:resp.errCode withMessage:/*[self errorMsgWithCode:resp.errCode]*/nil];
        }
    }
    self.callBackID = nil;
}
- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGWXPayAppidNotSame:
            return @"HBuilder mainifest.json中配置的支付appid和生成订单使用的appid不一致,如果是HB调试请在线打包";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}
//
//- (NSString*)errorMsgWithCode:(int)errorCode {
//    switch (errorCode) {
//        case WXErrCodeAuthDeny:
//            return @"授权失败";
//        case WXErrCodeSentFail:
//            return @"发送失败";
//        case WXErrCodeUserCancel:
//            return @"用户点击取消并返回,或者上次支持未完成";
//        case WXErrCodeUnsupport:
//            return @"微信不支持";
//        case WXErrCodeCommon:
//            return @"普通错误类型,可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等";
//        default:
//            break;
//    }
//    return [super errorMsgWithCode:errorCode];
//}

- (void)handleOpenURL:(NSNotification*)notification {
    if ( self.isRevOpenUrl ) {
        [WXApi handleOpenURL:[notification object] delegate:self];
        self.isRevOpenUrl = false;
    }
}
- (void)handleUniversalLinks:(NSNotification*)notification {
    if ( self.isRevOpenUrl ) {
        [WXApi handleOpenUniversalLink:[notification object] delegate:self];
        self.isRevOpenUrl = false;
    }
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUrlNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PDRCoreOpenUniversalLinksNotification
                                                  object:nil];
}

@end
