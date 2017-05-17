//
//  NSObject+QHOauthInfo.m
//  QHOauth
//
//  Created by MacPro on 15-9-16.
//  Copyright (c) 2015年 MacPro. All rights reserved.
//

#import "QHOauthInfo.h"
#import "PDRCommonString.h"


const NSString* pQHOAUTH_QID            = @"qid";
const NSString* pQHOAUTH_ACCOUNT        = @"account";
const NSString* pQHOAUTH_ACCOUNTDATA    = @"accountdata";
const NSString* pQHOAUTH_inputAccount   = @"inputAccount";
const NSString* pQHOAUTH_UserName       = @"key_username";
const NSString* pQHOAUTH_NickName       = @"key_nickname";
const NSString* pQHOAUTH_LoginEmail     = @"key_loginemail";
const NSString* pQHOAUTH_HeadPicURL     = @"key_avatorurl";
const NSString* pQHOAUTH_LoginQ         = @"q";
const NSString* pQHOAUTH_LoginT         = @"t";
const NSString* pQHOAUTH_SECMobile      = @"key_secmobile";
const NSString* pQHOAUTH_AccessToken    = @"access_token";
const NSString* pQHOAUTH_ISEXISTPHONE   = @"isExistPhone";
const NSString* pQHOAUTH_AUTHRESULT     = @"authResult";
const NSString* PQHOAUTH_USERINFO       = @"userInfo";

@interface QHOauthInfo ()

@property (nonatomic, retain)NSString* qid;
@property (nonatomic, retain)NSString* inputAccount;
@property (nonatomic, retain)NSString* userName;
@property (nonatomic, retain)NSString* nickName;
@property (nonatomic, retain)NSString* loginEmail;
@property (nonatomic, retain)NSString* headpicURL;
@property (nonatomic, retain)NSString* Q;
@property (nonatomic, retain)NSString* T;
@property (nonatomic, retain)NSString* loginInfoPath;
@property (nonatomic, retain)NSString* secMobile;
@property (nonatomic, retain)NSString* accessToken;

@end


static QHOauthInfo* g_QHOauthHandle = nil;

@implementation QHOauthInfo
@synthesize qid;
@synthesize inputAccount;
@synthesize userName;
@synthesize nickName;
@synthesize loginEmail;
@synthesize headpicURL;
@synthesize Q;
@synthesize T;
@synthesize loginInfoPath;
@synthesize secMobile;
@synthesize accessToken;


+ (id)instance
{
    if (g_QHOauthHandle == nil) {
        g_QHOauthHandle = [[QHOauthInfo alloc] init];
    }
    return g_QHOauthHandle;
}

+ (id)instance:(NSString*)pAppDataPath
{
    g_QHOauthHandle = [self instance];
    
    // 拼接文件路径
    g_QHOauthHandle.loginInfoPath = [pAppDataPath stringByAppendingPathComponent:@"QHOauth.plist"];
    
    return g_QHOauthHandle;
}


- (id)readOauthInfo
{
    // 在这里读取文件初始化
    if (g_QHOauthHandle.loginInfoPath) {
        NSDictionary* pReadDic = [NSDictionary dictionaryWithContentsOfFile:g_QHOauthHandle.loginInfoPath];
        if (pReadDic) {
            g_QHOauthHandle.qid = [pReadDic objectForKey:pQHOAUTH_QID];
            g_QHOauthHandle.inputAccount = [pReadDic objectForKey:pQHOAUTH_inputAccount];
            g_QHOauthHandle.userName = [pReadDic objectForKey:pQHOAUTH_UserName];
            g_QHOauthHandle.nickName = [pReadDic objectForKey:pQHOAUTH_NickName];
            g_QHOauthHandle.loginEmail = [pReadDic objectForKey:pQHOAUTH_LoginEmail];
            g_QHOauthHandle.T = [pReadDic objectForKey:pQHOAUTH_LoginT];
            g_QHOauthHandle.Q = [pReadDic objectForKey:pQHOAUTH_LoginQ];
            g_QHOauthHandle.headpicURL = [pReadDic objectForKey:pQHOAUTH_HeadPicURL];
            g_QHOauthHandle.secMobile = [pReadDic objectForKeyedSubscript:pQHOAUTH_SECMobile];
            g_QHOauthHandle.accessToken = [pReadDic objectForKey:pQHOAUTH_AccessToken];
        }
    }
    
    return g_QHOauthHandle;
}

- (id)initalize:(QUCUserModel*)user
{
    self.Q = user.Q;
    self.T = user.T;
    self.qid = user.qid;
    self.inputAccount = user.inputAccount;
    self.nickName = user.nickName;
    self.loginEmail = user.loginEmail;
    self.headpicURL = user.headPic;
    self.userName = user.userName;
    self.secMobile = user.secMobileNumber;
    
    return self;
}


- (void)saveOauthInfo
{
    // 保存文件的路径
    NSDictionary* pDiction = [self getOauthInfo];
    if(pDiction)
    {
        // 转换成NSData
        NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:pDiction
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                             errorDescription:nil];
        
        // 保存到文件，
        [plistData writeToFile:self.loginInfoPath atomically:NO];
    }
}

- (void)setToken:(NSString*)pToken
{
    accessToken = [[NSString alloc] initWithString:pToken];
}


- (void)removeOauthInfo
{
    // 删除文件
    [[NSFileManager defaultManager] removeItemAtPath:self.loginInfoPath error:nil];
}


- (NSDictionary*)getOauthInfo
{
    NSMutableDictionary* pDiction = [NSMutableDictionary dictionary];
    if(pDiction)
    {
        [pDiction setObject:self.qid?self.qid:@"" forKey:pQHOAUTH_QID];
        [pDiction setObject:self.inputAccount?self.inputAccount:@"" forKey:pQHOAUTH_inputAccount];
        [pDiction setObject:self.loginEmail?self.loginEmail:@"" forKey:pQHOAUTH_LoginEmail];
        [pDiction setObject:self.nickName?self.nickName:@"" forKey:pQHOAUTH_NickName];
        [pDiction setObject:self.userName?self.userName:@"" forKey:pQHOAUTH_UserName];
        [pDiction setObject:self.headpicURL?self.headpicURL:@"" forKey:pQHOAUTH_HeadPicURL];
        [pDiction setObject:self.Q?self.Q:@"" forKey:pQHOAUTH_LoginQ];
        [pDiction setObject:self.T?self.T:@"" forKey:pQHOAUTH_LoginT];
        [pDiction setObject:self.secMobile?self.secMobile:@"" forKey:pQHOAUTH_SECMobile];
    }
    
    return pDiction;
}


// 根据格式生成回调JS页面的Dic
- (NSDictionary*)CallbackInfo
{
    NSMutableDictionary* RetDic = [NSMutableDictionary dictionary];
    
    if (RetDic) {
        NSMutableDictionary* authResult = [NSMutableDictionary dictionary];
        if (authResult) {
            [authResult setObject:self.accessToken?self.accessToken:@"" forKeyedSubscript:pQHOAUTH_AccessToken];
            [RetDic setObject:authResult forKey:pQHOAUTH_AUTHRESULT];
        }
        
        NSMutableDictionary* userinfo = [NSMutableDictionary dictionary];
        if (userinfo) {
            [userinfo setObject:self.Q?self.Q:@"" forKey:pQHOAUTH_LoginQ];
            [userinfo setObject:self.T?self.T:@"" forKey:pQHOAUTH_LoginT];
            [userinfo setObject:self.qid?self.qid:@"" forKey:pQHOAUTH_QID];
            [userinfo setObject:self.inputAccount?self.inputAccount:@"" forKey:pQHOAUTH_ACCOUNT];

            NSMutableDictionary* pAccountData = [NSMutableDictionary dictionary];
            if (pAccountData) {
                [pAccountData setObject:self.inputAccount?self.inputAccount:@"" forKey:pQHOAUTH_inputAccount];
                [pAccountData setObject:self.loginEmail?self.loginEmail:@"" forKey:pQHOAUTH_LoginEmail];
                [pAccountData setObject:self.nickName?self.nickName:@"" forKey:@"nickname"];
                [pAccountData setObject:self.userName?self.userName:@"" forKey:pQHOAUTH_UserName];
                [pAccountData setObject:self.headpicURL?self.headpicURL:@"" forKey:@"headimgurl"];
                [pAccountData setObject:self.secMobile?self.secMobile:@"" forKeyedSubscript:pQHOAUTH_SECMobile];
                [userinfo setObject:pAccountData forKeyedSubscript:pQHOAUTH_ACCOUNTDATA];
            }
            [RetDic setObject:userinfo forKey:PQHOAUTH_USERINFO];
        }
    }
    return RetDic;
}



/*
 */
- (void)clearOauthInfo
{
    self.qid = nil;
    self.inputAccount = nil;
    self.loginEmail = nil;
    self.nickName = nil;
    self.userName = nil;
    self.headpicURL = nil;
    self.Q = nil;
    self.T = nil;
    self.secMobile = nil;
    self.accessToken = nil;
}


- (void)dealloc
{
    [self clearOauthInfo];
    [super dealloc];
}


@end
