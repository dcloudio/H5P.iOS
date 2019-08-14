//
//  QHOauth.m
//  QHOauth
//
//  Created by MacPro on 15-9-16.
//  Copyright (c) 2015年 MacPro. All rights reserved.
//
#import "PGQHOauth.h"
#import "QHOauthInfo.h"
#import "PDRCoreApp.h"
#import "PDRCoreAppInfo.h"
#import <qucFrameWorkAll/qucFrameWorkAll.h>
#include "DCNavigationController.h"
#include "DCAddPhoneNumber.h"


// local arguments
NSString* QCAutoLoginNotification = @"QUCAutoLoginNotification";
NSString* URL_OPENAPI_OAUTH2_AUTHORIZE = @"https://openapi.360.cn/oauth2/authorize.json?client_id=%@&response_type=token&redirect_uri=oob&state=%@&scope=basic&version=Qhopensdk-1.1.6&DChannel=default&display=mobile.cli_v1&oauth2_login_type=%d";

static NSString* URL_OPENAPI_USER_ME = @"https://openapi.360.cn/user/me.json?access_token=%@&fields=%@";
static NSString* URL_PROFILE_HASPHONE = @"http://profile.sj.360.cn/raffle/sh_raffle/has-phone";

extern const NSString* pQHOAUTH_LoginQ;
extern const NSString* pQHOAUTH_LoginT;
extern const NSString* pQHOAUTH_AUTHRESULT;
extern const NSString* PQHOAUTH_USERINFO;
extern const NSString* pQHOAUTH_AccessToken;
// static argyments
static PGQHOauth* g_sQHOAuthHandle = nil;


/*
 * 奇虎登陆Controller
 */
@interface DCLoginViewController : QUCLoginViewController <DCNavigationControllerDelegate>

@property (nonatomic, retain)PGQHOauth* pOuathHandle;

@end


@interface QHOauthHTTPGetTokenDelegate : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, retain)PGQHOauth* pOauthHandle;
@end



/*
 *
 */
@interface PGQHOauth()
{
    bool    bShowLoginPage;
    QHOauthInfo* pQHOauthInfo;
    QUCAutoLoginModel* qucAutoLogin;
}
@property(nonatomic, assign)DCNavigationController* pNavController;
@property(nonatomic, assign)BOOL bisGlobalLogin;
@property(nonatomic, assign)NSString* pOauthAppKey;
@property(nonatomic, retain)NSString* pUserToken;

- (void)handleAutoLoginCallback:(NSNotification *)notification;
- (void)showQHLoginController;
- (void)handleAutoLoginData:(NSDictionary *)dict;
- (void)setCurrentToken:(NSString*)pToken;
@end


@implementation PGQHOauth
@synthesize pCallBackID;
@synthesize pChannelID;
@synthesize pDestKey;
@synthesize pParams;
@synthesize pSignKey;
@synthesize pAppid;
@synthesize pNavController;
@synthesize bisGlobalLogin;
@synthesize pOauthAppKey;
@synthesize pUserToken;

#define DeviceId ([UIDevice currentDevice].identifierForVendor.UUIDString)

- (id)init
{
    if (self = [super init])
    {
        NSDictionary* dhDic = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"qihoo"];
        if (dhDic) {
            self.pChannelID = [dhDic objectForKey:@"channelid"];
            self.pDestKey = [dhDic objectForKey:@"destkey"];
            self.pSignKey = [dhDic objectForKey:@"signkey"];
            self.bisGlobalLogin = YES;
            self.identify = @"qihoo";
            self.note = @"奇虎360";
            self.pNavController = nil;
            self.pUserToken = nil;
            bShowLoginPage = false;
            g_sQHOAuthHandle = self;
        }
    }
    
    return self;
}

// 初始化用户信息
- (void)initalize
{
    if (self.pChannelID != nil && self.pSignKey != nil && self.pDestKey != nil) {
        [QUCInterface sharedQUCInterfaceWithSrc:self.pChannelID Mid:DeviceId SignKey:self.pSignKey DesKey:self.pDestKey];
    }
    
    if (self.bisGlobalLogin) {
        NSArray* pArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        pQHOauthInfo = [QHOauthInfo instance: [pArray objectAtIndex:0]];
    }
    else{
        pQHOauthInfo = [QHOauthInfo instance: self.appContext.appInfo.dataPath];
    }
    
    // 读取保存的文件，如果文件存在尝试自动登陆，如果不成功打开controller
    NSDictionary* pSaveDic = [[pQHOauthInfo readOauthInfo] getOauthInfo];
    
    if (pSaveDic && [[pSaveDic objectForKey:pQHOAUTH_LoginQ] length] > 0
        && [[pSaveDic objectForKey:pQHOAUTH_LoginT] length] > 0) {
        
        NSString* pQ = [pSaveDic objectForKey:pQHOAUTH_LoginQ];
        NSString* pT = [pSaveDic objectForKey:pQHOAUTH_LoginT];
        
        // 添加监听事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAutoLoginCallback:) name:QCAutoLoginNotification object:nil];
        qucAutoLogin = [[QUCAutoLoginModel alloc] init];
        if (qucAutoLogin) {
            [qucAutoLogin autoLoginWithQ:pQ T:pT Progress: nil];
        }
    }
    
    
    [super initalize];
}


// 用户点击现实登陆页面或者默认登陆
- (void)login:(NSString*)cbId withParams:(NSDictionary*)params
{
    self.pCallBackID = cbId;
    if ([[pParams allKeys] containsObject:@"appkey"])
        self.pOauthAppKey = [pParams objectForKey:@"appkey"];
    else
        self.pOauthAppKey = @"08158bf9f09b919790a63f10c381be52";
    // 读取保存的文件，如果文件存在尝试自动登陆，如果不成功打开controller
    NSDictionary* pSaveDic = [[pQHOauthInfo readOauthInfo] getOauthInfo];
    
    if (pSaveDic && [[pSaveDic objectForKey:pQHOAUTH_LoginQ] length] > 0
        && [[pSaveDic objectForKey:pQHOAUTH_LoginT] length] > 0) {
        
        NSString* pQ = [pSaveDic objectForKey:pQHOAUTH_LoginQ];
        NSString* pT = [pSaveDic objectForKey:pQHOAUTH_LoginT];
        [self getToken:pOauthAppKey WithQ:pQ AndT:pT];
    }
    else{
        [self showQHLoginController];
        
    }
    
    
}


// 设置当前Appkey的token
- (void)setCurrentToken:(NSString*)pToken
{
    pUserToken = [[NSString alloc] initWithString:pToken];
    [pQHOauthInfo setToken:pToken];
    [self executeJSSucessCallback];
    
    //获取是否绑定手机号，如果没有直接弹出绑定手机号的窗口
    // 先请求用户信息
    // 如果是无界面登陆不显示
    if (bShowLoginPage)
    {
        // 标识登陆页面已经关闭
        bShowLoginPage = false;
        NSMutableURLRequest* pRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URL_PROFILE_HASPHONE]];
        if (pRequest) {
            [pRequest setHTTPMethod:@"GET"];
            NSOperationQueue *queue = [[NSOperationQueue alloc]init];
            [NSURLConnection sendAsynchronousRequest:pRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                
                if (!error)
                {
                    // 确定获取到手机信息
                    NSDictionary* pLoginDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                    bool nHasPhoneNo = [[pLoginDic objectForKey:@"data"] boolValue];
                    if (!nHasPhoneNo) {
                        [self addPhoneNumber:nil];
                    }
                }
            }];
        }
    }
}


// 删除用户登陆信息
- (void)logout:(NSString*)cbId
{
    self.pCallBackID = cbId;
    // 删除已经保存的Login文档xx
    [pQHOauthInfo removeOauthInfo];
    [pQHOauthInfo clearOauthInfo];
    
    // 回调通知用户信息删除成功
    [self executeJSSucessCallback];
    self.pCallBackID = nil;
}



// 获取用户信息
- (void)getUserInfo:(NSString*)cbId
{
    NSString* pUserInfoURl = nil;
    NSString* pHasPhoneUrl = nil;
    NSString* fields = @"id,name,avatar,sex,area,nick";
    static NSMutableDictionary* pDicUserInfo = nil;
    static int nHasPhoneNo = -1;
    
    if (pUserToken) {
        
        pHasPhoneUrl = URL_PROFILE_HASPHONE;
        pUserInfoURl = [NSString stringWithFormat:URL_OPENAPI_USER_ME, pUserToken, fields];
        
        // 先请求用户信息
        NSMutableURLRequest* pRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pUserInfoURl]];
        if (pRequest) {
            [pRequest setHTTPMethod:@"GET"];
            NSOperationQueue *queue = [[NSOperationQueue alloc]init];
            [NSURLConnection sendAsynchronousRequest:pRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                
                if (error) {
                    [self toErrorCallback:cbId withCode:-2 withMessage:@"Request Error"];
                }
                else
                {
                    // 获取到用户信息
                    NSDictionary* pLoginDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                    pDicUserInfo = [[NSMutableDictionary alloc] initWithDictionary:pLoginDic];
                    
                    [pRequest setURL:[NSURL URLWithString:pHasPhoneUrl]];
                    // 获取手机绑定信息
                    [NSURLConnection sendAsynchronousRequest:pRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                            
                    if (error) {
                        [self toErrorCallback:cbId withCode:-2 withMessage:@"Request Error"];
                    }
                    else
                    {
                        // 确定获取到手机信息
                        NSDictionary* pLoginDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                        nHasPhoneNo = [[pLoginDic objectForKey:@"data"] boolValue];
                        [self excuteUserInfoCallBack:pDicUserInfo HasPhoneNo:nHasPhoneNo CallBackID:cbId];
                    }
                    }];
                    
                }
                [pRequest release];
            }];
        }
    }
    else
    {
        [self toErrorCallback:cbId withCode:-2 withMessage:@"Request Error"];
    }
}


- (void)addPhoneNumber:(NSString*)cbId
{
    DCAddPhoneNumber* pAddPhoneNumberContrller = [[DCAddPhoneNumber alloc] init];
    pAddPhoneNumberContrller.pOuathHandle  = self;
    [self presentViewController:pAddPhoneNumberContrller animated:YES completion:nil];
    [pAddPhoneNumberContrller release];
}


// 现实QH登陆页面
- (void)showQHLoginController
{
    // 调用现实登陆页面
    DCLoginViewController* pQHLoginController = [[DCLoginViewController alloc] init];
    if (pQHLoginController != nil) {
        pNavController = [[DCNavigationController alloc] init];
        if (pNavController) {
            pNavController.customQucNavDelegate = pQHLoginController;
            pQHLoginController.pOuathHandle = self;
            [self presentViewController:pNavController animated:YES completion:nil];
            // 推送Controller 不然会不能显示返回按钮
            [pNavController pushViewController:pQHLoginController animated:YES];
            // 标记已经显示了登陆页面
            bShowLoginPage = true;

            [pNavController release];
        }
        [pQHLoginController release];
    }
}


// 默认登陆返回回调
-(void)handleAutoLoginCallback:(NSNotification *)notification
{
    //解除广播监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:QCAutoLoginNotification object:nil];
    
    NSDictionary *theData = [notification userInfo];
    [self handleAutoLoginData:theData];
    if(qucAutoLogin)
        [qucAutoLogin release];
}


-(void)handleAutoLoginData:(NSDictionary *)dict
{
    int errCode = [[dict objectForKey:@"errCode"] intValue];
    //提示错误信息
    if(errCode != QUC_ERROR_TYPE_SUCCESS) {
        // 调用现实登陆页面
        [self showQHLoginController];
        return;
    }
    
    //自动登录成功
    QUCUserModel *qucUser = [dict objectForKey:@"dataDict"];
    
    //判断是否返回了新的QT，新的Q和T 都存在且不为空时再替换
    if( qucUser.Q.length > 0 && qucUser.T.length > 0){
        //[self showToastAlertViewWithMsg:@"返回了新的QT信息"];
        // 保存到文件
        [[pQHOauthInfo initalize:qucUser] saveOauthInfo];
    }
    
    [self updataCookies];
    
    // 如果Appkey不为空则去获取token
    if (self.pOauthAppKey != nil) {
        NSDictionary* pSaveDic = [[pQHOauthInfo readOauthInfo] getOauthInfo];
        if (pSaveDic) {
            // 获取appkey
            [self getToken:self.pOauthAppKey WithQ:[pSaveDic objectForKey:pQHOAUTH_LoginQ] AndT:[pSaveDic objectForKey:pQHOAUTH_LoginT]];
            
        }
    }
    else
    {
        // 返回结果到页面
        [self executeJSSucessCallback];
    }
}

// 更新当前所有请求的Cookie
- (void)updataCookies
{
    NSDictionary* pOauthDic = [[pQHOauthInfo readOauthInfo] getOauthInfo];
    if (pOauthDic && [[pOauthDic objectForKey:pQHOAUTH_LoginQ] length] > 0
        && [[pOauthDic objectForKey:pQHOAUTH_LoginT] length] > 0) {
        
        // 初始化以后为所有的
        NSURL* cookieURL = [NSURL URLWithString:@"https://*.360.cn"];
        
        NSDictionary *cookieProperties = [NSMutableDictionary dictionary];
        [cookieProperties setValue:[pOauthDic objectForKey:pQHOAUTH_LoginQ] forKey:NSHTTPCookieValue];
        [cookieProperties setValue:@"Q" forKey:NSHTTPCookieName];
        [cookieProperties setValue:@".360.cn" forKey:NSHTTPCookieDomain];
        [cookieProperties setValue:@"/" forKey:NSHTTPCookiePath];
        
        NSDictionary *cookieProperties1 = [NSMutableDictionary dictionary];
        [cookieProperties1 setValue:[pOauthDic objectForKey:pQHOAUTH_LoginT] forKey:NSHTTPCookieValue];
        [cookieProperties1 setValue:@"T" forKey:NSHTTPCookieName];
        [cookieProperties1 setValue:@".360.cn" forKey:NSHTTPCookieDomain];
        [cookieProperties1 setValue:@"/" forKey:NSHTTPCookiePath];
        
        
        NSHTTPCookie *cookie = [[NSHTTPCookie alloc]initWithProperties:cookieProperties];
        NSHTTPCookie *cookie1 = [[NSHTTPCookie alloc]initWithProperties:cookieProperties1];
        
        NSArray *cooikes = [NSArray arrayWithObjects:cookie1,cookie, nil];
        
        if (cookie) {
            [cookie release];
        }
        
        if (cookie1) {
            [cookie1 release];
        }
        if ( cooikes ) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cooikes forURL:cookieURL mainDocumentURL:nil];
        }
    }
}



- (void)getToken:(NSString*)pAppkey WithQ:(NSString*)Qstr AndT:(NSString*)TStr
{
    NSString* state = @"LifeGetToken"; // state是OAUTH2给应用提供的一个安全机制 应用可以自己指定一个值进去 后边会原样返回
    int oauth2LoginType = 2;
    
    // 生成URL
    NSString* pUrl = [NSString stringWithFormat:URL_OPENAPI_OAUTH2_AUTHORIZE, pAppkey, state, oauth2LoginType];
    
    // 设置Cookie
    NSMutableURLRequest* pRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pUrl]];
    
    if (pRequest) {
        [pRequest setHTTPMethod:@"GET"];
        
        QHOauthHTTPGetTokenDelegate* pDelegate = [[QHOauthHTTPGetTokenDelegate alloc] init];
        if (pDelegate) {
            [pDelegate setPOauthHandle:self];
            NSURLConnection* pConnection = [[[NSURLConnection alloc] initWithRequest:pRequest delegate:pDelegate] autorelease];
            if (pConnection != nil) {
                [pConnection start];
            }
            [pDelegate release];
        }
        [pRequest release];
    }
}

// 回调通知用户信息
- (void)executeJSSucessCallback
{
    NSDictionary* pLoginDic = [pQHOauthInfo CallbackInfo];
    if (pLoginDic) {
        PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:pLoginDic];
        [self toCallback:self.pCallBackID withReslut:[outJS toJSONString]];
    }
}

// 获取用户信息
- (BOOL)excuteUserInfoCallBack:(NSMutableDictionary*)pUserInfo HasPhoneNo:(int)nHasPhone CallBackID:(NSString*)cbid
{
    if (nHasPhone != -1 && pUserInfo != nil) {
        [pUserInfo setValue:[NSNumber numberWithBool:nHasPhone] forKey:@"isExistPhone"];
        
        NSMutableDictionary* RetDic = [NSMutableDictionary dictionary];
        [RetDic setObject:pUserInfo forKey:PQHOAUTH_USERINFO];
        
        NSMutableDictionary* authResult = [NSMutableDictionary dictionary];
        if (authResult) {
            [authResult setObject:pUserToken?pUserToken:@"" forKeyedSubscript:pQHOAUTH_AccessToken];
            [RetDic setObject:authResult forKey:pQHOAUTH_AUTHRESULT];
        }
                
        PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:RetDic];
        [self toCallback:cbid withReslut:[outJS toJSONString]];
        return true;
    }
    return false;
}

- (void)dealloc
{
    self.pAppid = nil;
    [super dealloc];
}

@end


/*
 * 登陆页面
 */
@implementation DCLoginViewController

//设置关闭按钮
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


// 用户点击取消
- (void)leftNavBtnClick:(id)sender;
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.pOuathHandle toErrorCallback:self.pOuathHandle.pCallBackID
                              withCode:-100 withMessage:@"User Cancled"];
}

// 登陆失败回调
- (void)qucLoginFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.pOuathHandle toErrorCallback:self.pOuathHandle.pCallBackID
                              withCode:errCode withMessage:errMsg];
    
}

// 登陆成功回调
- (void)qucLoginSuccessedWithQuser:(QUCUserModel *)user
{
    // 初始化 解析
    QHOauthInfo* pOauthInfo = [[QHOauthInfo instance] initalize:user];
    
    // 保存信息
    [pOauthInfo saveOauthInfo];
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.pOuathHandle updataCookies];
    
    // 如果Appkey不为空则去获取token
    if (self.pOuathHandle.pOauthAppKey != nil) {
        // 获取appkey
        [self.pOuathHandle getToken:self.pOuathHandle.pOauthAppKey WithQ:user.Q AndT:user.T];
    }
    else
    {
        // 回调页面
        [self.pOuathHandle executeJSSucessCallback];
    }
    
    
    
}

@end

/***奇虎登陆流程页面Controller Start****/

/*
 * 重新设置密码Controller
 */
@interface DCSetPwdViewController : QUCSetPwdViewController

@end

@implementation DCSetPwdViewController


#pragma mark --登录失败的回调；如程序非验证码、密码、帐号未激活等错误外，回调在这里
-(void) qucLoginFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg
{
    [g_sQHOAuthHandle toErrorCallback:g_sQHOAuthHandle.pCallBackID
                             withCode:errCode
                          withMessage:errMsg];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark --登录成功的回调
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user
{
    [[[QHOauthInfo instance] initalize:user] saveOauthInfo];
    [g_sQHOAuthHandle executeJSSucessCallback];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
    [g_sQHOAuthHandle updataCookies];
    
}

@end


/*
 * 发送短信注册成功Controller
 */
@interface DCSendSmsCodeForRegViewController : QUCSendSmsCodeForRegViewController

@end

@implementation DCSendSmsCodeForRegViewController

#pragma mark --用户注册失败回调，默认为弹toast提示
-(void) qucRegFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg
{
    [g_sQHOAuthHandle toErrorCallback:g_sQHOAuthHandle.pCallBackID
                             withCode:errCode
                          withMessage:errMsg];
    
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark --用户注册成功回调
-(void) qucRegSuccessedWithQuser:(QUCUserModel *)user
{
    [[[QHOauthInfo instance] initalize:user] saveOauthInfo];
    [g_sQHOAuthHandle executeJSSucessCallback];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
    [g_sQHOAuthHandle updataCookies];
}

@end



/*
 * 邮件注册回调Controller
 */
@interface DCRegByEmailViewController : QUCRegByEmailViewController

@end

@implementation DCRegByEmailViewController

//业务方重载此方法，当帐号登录成功后回调
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user
{
    [[[QHOauthInfo instance] initalize:user] saveOauthInfo];
    [g_sQHOAuthHandle executeJSSucessCallback];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
    [g_sQHOAuthHandle updataCookies];
}

//业务方重载此方法，注册不需要激活时，注册成功回调
-(void) qucRegSuccessedWithQuser:(QUCUserModel *)user
{
    [[[QHOauthInfo instance] initalize:user] saveOauthInfo];
    [g_sQHOAuthHandle executeJSSucessCallback];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
    [g_sQHOAuthHandle updataCookies];
}

//业务方重载此方法，除需要显示验证码、帐号已存在等错误外，回调此方法；父类默认显示toast view
-(void) qucRegFailedWithErrno:(int)errCode ErrorMsg:(NSString *)errMsg
{
    [g_sQHOAuthHandle toErrorCallback:g_sQHOAuthHandle.pCallBackID
                             withCode:errCode
                          withMessage:errMsg];
    
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
}
@end


/*
 * 电话号码注册回调Controller
 */
@interface DCRegByMobileViewController : QUCRegByMobileViewController

@end

@implementation DCRegByMobileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.regByMobileView.regModeSwitchBtn.frame = CGRectZero;
}

//业务方重载此方法，当帐号已存在，且登录成功后回调
-(void) qucLoginSuccessedWithQuser:(QUCUserModel *)user
{
    [[[QHOauthInfo instance] initalize:user] saveOauthInfo];
    [g_sQHOAuthHandle executeJSSucessCallback];
    [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
    [g_sQHOAuthHandle updataCookies];
}

@end

/***奇虎登陆流程页面Controller end****/

/***奇虎登陆获取应用token start****/

@implementation QHOauthHTTPGetTokenDelegate
@synthesize pOauthHandle;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    
    NSDictionary* m_GetHeadDictionary = [NSMutableDictionary dictionaryWithDictionary:[httpResponse allHeaderFields]];
    if ([[m_GetHeadDictionary allKeys] containsObject:@"Location"])
    {
        NSString* pString = [m_GetHeadDictionary objectForKey:@"Location"];
        ///page/oauth2_succeed?state=LifeGetToken#access_token=379848396a112a6c23149981cdad56e6751f77335cf862bd3&expires_in=36000
        NSRange tokenRange = [pString rangeOfString:@"(?:[^/#=])*\\&" options:NSRegularExpressionSearch];
        if (tokenRange.location > 0 && tokenRange.length > 0) {
            tokenRange.length -= 1;
            [pOauthHandle setCurrentToken:[pString substringWithRange:tokenRange]];
            
        }
    }
    else{
        [g_sQHOAuthHandle toErrorCallback:g_sQHOAuthHandle.pCallBackID
                                 withCode:-1
                              withMessage:@"getTokenError"];
        if (g_sQHOAuthHandle.pNavController)
        {
            [g_sQHOAuthHandle.pNavController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (NSURLRequest*)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    // 禁止进行页面跳转
    NSURLRequest *newRequest = request;
    if (response) {
        newRequest = nil;
    }
    return newRequest;
}
@end

/***奇虎登陆获取应用token end****/
