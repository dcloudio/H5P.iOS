//
//  UIViewController+DCAddPhoneNumber.m
//  qucsdkDemo
//
//  Created by Linxinzheng on 15-9-28.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import "DCAddPhoneNumber.h"
#import <qucFrameWorkAll/qucFrameWorkAll.h>
#import <Foundation/Foundation.h>
#import "DCNavigationBar.h"

NSString* pStringGetSmsCode = @"获取验证码";
NSString* pStringGetBinding = @"立即绑定";
NSString* pStringTitleLable = @"亲，完善信息才能享受更多的优惠哦！";
NSString* pStringPlacePhone = @"请输入手机号";
NSString* pStringPlaceVeri  = @"请输入验证码";
NSString* LIFE_HELPER_HOST = @"http://profile.sj.360.cn";
NSString* LIFE_HELPER_GETVERCODE = @"/live/get-vc";
NSString* LIFE_HELPER_BINDPHONENUMBER = @"/live/set-phone";

/*动画时间*/
static const CGFloat NavBarOriginY     = 20.0;//导航栏的Y坐标
static const CGFloat NavBarOriginYIos7 = 0.0;//IOS7下的导航栏Y坐标
static const CGFloat NavBarHeight      = 44.0;//系统默认导航高度
static const CGFloat NavBarHeightIos7  = 64.0;//IOS7下的导航栏高度


#define IOS7_OR_LATER [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0

#define NAV_BAR_FRAME  IOS7_OR_LATER ? CGRectMake(0.0, NavBarOriginYIos7, qucScreenWidth, NavBarHeightIos7) : \
CGRectMake(0.0, NavBarOriginY, qucScreenWidth, NavBarHeight)



@interface DCAddPhoneNumber()
{
    UITextField* inputSmsBinding;
    UITextField* inputPhoneNumber;
    UIButton*  buttonSendPhoneNumber;
    UIButton*   buttonSendBinging;
    NSString*   pStringPhoneNumber;
    NSString*   pVerificationCode;
    UILabel*    pTipsTosta;
    NSTimer*    pTostaTimer;
}

@property   (nonatomic,strong)   DCNavigationBar *customNavBar;
- (int)getlayoutSize:(NSString*)pLayout;

@end

@implementation DCAddPhoneNumber
@synthesize customNavBar = _customNavBar;



- (void)viewDidAppear:(BOOL)animated
{
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // 单独引入一个导航栏
    _customNavBar = [[DCNavigationBar alloc] initWithFrame:NAV_BAR_FRAME];

    [_customNavBar.backBtn addTarget:self action:@selector(leftBtnTouchDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_customNavBar];
    [_customNavBar setNavTitle:@"关联手机"];
    _customNavBar.showBackbtnFlag = YES;
    _customNavBar.showRightBtnFlag = NO;
    [_customNavBar moveNavLablePox];
    
    // 配置高度
    int nItemTopValue = (int) _customNavBar.frame.size.height;
    int nItemMargin = 5;
    
    //
    int nItemHeight =  [self getlayoutSize:@"qucBigHeight"];
    // 左右留白
    int qucPanddingWidht = [self getlayoutSize:@"qucPaddingWidth"];
    // 控件间距
    int qucBigVerticalInterVal = [self getlayoutSize:@"qucBigVerticalInterval"];
    
    int nItemPaddingHeight = [self getlayoutSize:@"qucLittleHeight"];
    UIFont* pFontLable = [self getFont:@"qucLabelFieldFont"];
    UIColor* pLableColor = [self getColorByHex:@"#888686"];
    int nLableHeight = [self getlayoutSize:@"qucLittleHeight"];
    
    
    // 提示文字
    UILabel* pTilteLable = [[UILabel alloc] initWithFrame:CGRectMake(qucPanddingWidht, nItemTopValue, (self.view.frame.size.width - qucPanddingWidht * 2), nLableHeight)];
    [pTilteLable setText:pStringTitleLable];
    [pTilteLable setTextColor:pLableColor];
    [pTilteLable setFont:pFontLable];
    [pTilteLable setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:pTilteLable];
    [pTilteLable release];
    // 重新计算下一个item的top值
    nItemTopValue = nItemTopValue + nLableHeight + qucBigVerticalInterVal;
    
    
    int nItemWidth = (self.view.frame.size.width - qucPanddingWidht * 3) / 3;
    int nTextItemWidth = nItemWidth * 2 - nItemMargin * 2;
    int nTextItemHeight = nItemHeight - nItemMargin * 2;
    
    // 电话号码编辑框
    UIView* pPhoneNumberBGView = [[UIView alloc] initWithFrame:CGRectMake(qucPanddingWidht, nItemTopValue,  (nItemWidth * 2), nItemHeight)];
    pPhoneNumberBGView.layer.cornerRadius = 4;
    pPhoneNumberBGView.layer.masksToBounds = YES;
    //给图层添加一个有色边框
    pPhoneNumberBGView.layer.borderWidth = 1;
    pPhoneNumberBGView.layer.borderColor = [[self getColorByHex:@"#D8D8D8"] CGColor];
    inputPhoneNumber = [[UITextField alloc] initWithFrame:CGRectMake(nItemMargin, nItemMargin, nTextItemWidth, nTextItemHeight)];
    [pPhoneNumberBGView addSubview:inputPhoneNumber];
    [inputPhoneNumber setPlaceholder:pStringPlacePhone];
    [self.view addSubview:pPhoneNumberBGView];
    // 添加一个delegage
    [pPhoneNumberBGView release];
    
    // 发送短信按钮
    int xPos = pPhoneNumberBGView.frame.origin.x + pPhoneNumberBGView.frame.size.width + 10;
    buttonSendPhoneNumber = [UIButton buttonWithType:UIButtonTypeSystem];
    [buttonSendPhoneNumber setTitle:pStringGetSmsCode forState:UIControlStateNormal];
    [buttonSendPhoneNumber.titleLabel setFont:[UIFont systemFontOfSize:18]];
    buttonSendPhoneNumber.layer.borderColor = [[self getColorByHex:@"#4CC3F9"] CGColor];
    buttonSendPhoneNumber.layer.borderWidth = 2;
    buttonSendPhoneNumber.layer.cornerRadius = 4;
    buttonSendPhoneNumber.layer.masksToBounds = YES;
    buttonSendPhoneNumber.tag = 100;
    [buttonSendPhoneNumber setFrame:CGRectMake(xPos, nItemTopValue, nItemWidth + 10,  nItemHeight)];
    [buttonSendPhoneNumber addTarget:self action:@selector(buttonCallbac:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonSendPhoneNumber];
    
    // 重新计算下一个item的top值
    nItemTopValue = ( nItemTopValue + nItemPaddingHeight + nItemHeight);
    
    // 填写验证码编辑框
    int nWidth = self.view.frame.size.width - qucPanddingWidht * 2;
    UIView* pBindingView = [[UIView alloc] initWithFrame:CGRectMake(qucPanddingWidht, nItemTopValue, nWidth, nItemHeight)];
    pBindingView.layer.cornerRadius = 4;
    pBindingView.layer.masksToBounds = YES;
    //给图层添加一个有色边框
    pBindingView.layer.borderWidth = 1;
    pBindingView.layer.borderColor = [[self getColorByHex:@"#D8D8D8"] CGColor];
    inputSmsBinding = [[UITextField alloc] initWithFrame:CGRectMake(nItemMargin, nItemMargin, nWidth , (nItemHeight - nItemMargin * 2))];
    [pBindingView addSubview:inputSmsBinding];
    [inputSmsBinding setPlaceholder:pStringPlaceVeri];
   
    [self.view addSubview:pBindingView];
    [pBindingView release];
    
    // 重新计算下一个item的top值
    nItemTopValue = nItemTopValue + nItemPaddingHeight + nItemHeight;
    
    
    // 立即绑定按钮
    buttonSendBinging = [UIButton buttonWithType:UIButtonTypeSystem];
    [buttonSendBinging setTitle:pStringGetBinding forState:UIControlStateNormal];
    [buttonSendBinging.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [buttonSendBinging setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buttonSendBinging setBackgroundColor:[self getColorByHex:@"#4CC3F9"]];
    buttonSendBinging.layer.borderColor = [[self getColorByHex:@"#4CC3F9"] CGColor];
    buttonSendBinging.layer.borderWidth = 1;
    buttonSendBinging.layer.cornerRadius = 4;
    buttonSendBinging.layer.masksToBounds = YES;
    buttonSendBinging.tag = 101;
    [buttonSendBinging setFrame:CGRectMake(qucPanddingWidht, nItemTopValue, nWidth, nItemHeight)];
    [buttonSendBinging addTarget:self action:@selector(buttonCallbac:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonSendBinging];
 
    [super viewDidAppear:animated];

}

- (void)buttonCallbac:(id)sender
{
    // 关闭软键盘
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIButton* nButtonSender = (UIButton*)sender;
    switch (nButtonSender.tag) {
        case 100:
        {
            [self getVerificationCode];
        }
            break;
        case 101:
        {
            
            [self bindingPhoneNumber];
        }
            break;
        default:
            break;
    }
}

// 显示提示
- (void)showTipsTosta:(NSString*)pMsg
{
    //
    UIFont* pTipsFont = [self getFont:@"qucLabelFieldFont"];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:pTipsFont forKey:NSFontAttributeName];
    
    CGSize szSize = [pMsg sizeWithAttributes:attributes];
    
    pTipsTosta = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - szSize.width - 10) / 2, self.view.frame.size.height / 3 * 2, szSize.width + 10, szSize.height + 10)];
    
    pTipsTosta.backgroundColor = [UIColor blackColor];
    pTipsTosta.text = pMsg;
    pTipsTosta.textColor = [UIColor whiteColor];
    pTipsTosta.font = pTipsFont;
    pTipsTosta.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:pTipsTosta];
    [pTipsTosta release];
    
    // 渐现
    CGFloat oldAlpha = pTipsTosta.alpha;
    pTipsTosta.alpha = 0.0f;
    [UIView beginAnimations:@"animationID" context:nil];
    [UIView setAnimationDuration:0.7];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    pTipsTosta.alpha = oldAlpha;
    [UIView commitAnimations];
    
    pTostaTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(TostaViewEaseOut) userInfo:nil repeats:NO];
}

// 隐藏提示
- (void)TostaViewEaseOut
{
    // 渐隐
    [UIView beginAnimations:@"animationID" context:nil];
    [UIView setAnimationDuration:0.7];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDidStopSelector:@selector(removeTostaView)];
    pTipsTosta.alpha = 0.0f;
    [UIView commitAnimations];
    [pTostaTimer invalidate];
    pTostaTimer = nil;
}

// 删除提示lable
- (void)removeTostaView
{
    [pTipsTosta removeFromSuperview];
}

// 获取验证码
- (void)getVerificationCode
{
    pStringPhoneNumber = [[inputPhoneNumber text] retain];
    NSString* pVerString = [NSString stringWithFormat:@"http://profile.sj.360.cn/live/get-vc?mobile=%@", pStringPhoneNumber];
    
    NSMutableURLRequest* pRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pVerString]];
    [pRequest setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [NSURLConnection sendAsynchronousRequest:pRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        if (error) {
            // 网络错误
        }
        else
        {
            NSDictionary* pDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (pDic) {
                int pErrorNo = [[pDic objectForKey:@"errno"] intValue];
                if (pErrorNo != 0) {
                    // 显示一个错误提示框
                    NSString* pErrmsg = [pDic objectForKey:@"errmsg"];
                    [self performSelectorOnMainThread:@selector(showTipsTosta:) withObject:pErrmsg waitUntilDone:NO];
                }
            }
        }
        
        [pRequest release];
    }];
}


// 绑定手机号
- (void)bindingPhoneNumber
{
    pVerificationCode = [[inputSmsBinding text] retain];
    
    NSString* pVerString = [NSString stringWithFormat:@"http://profile.sj.360.cn/live/set-phone?mobile=%@&vc=%@", pStringPhoneNumber, pVerificationCode];
    
    NSMutableURLRequest* pRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:pVerString]];
    [pRequest setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [NSURLConnection sendAsynchronousRequest:pRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error) {
            // 网络错误
        }
        else
        {
            NSDictionary* pDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (pDic) {
                // 获取信息
                NSString* pErrmsg = [pDic objectForKey:@"errmsg"];
                // 错误码
                int pErrorNo = [[pDic objectForKey:@"errno"] intValue];
                
                if (pErrorNo != 0) {
                    // 显示一个错误提示框                    
                    [self performSelectorOnMainThread:@selector(showTipsTosta:) withObject:pErrmsg waitUntilDone:NO];
                }
                else
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    if (self.pOuathHandle.pCallBackID) {
                        PDRPluginResult *outJS = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsString:pErrmsg];
                        [self.pOuathHandle toCallback:self.pOuathHandle.pCallBackID withReslut:[outJS toJSONString]];
                    }
                }
            }
        }
        [pRequest release];
    }];
    
}

// 用户点击取消
- (void)leftBtnTouchDown:(id)sender;
{
    [self dismissViewControllerAnimated:YES completion:nil];

    if (self.pOuathHandle.pCallBackID) {
        [self.pOuathHandle toErrorCallback:self.pOuathHandle.pCallBackID
                                  withCode:-100 withMessage:@"User Cancled"];
        
    }
}

// 根据字符串获取颜色
- (UIColor*)getColorByHex:(NSString*)hexColor
{
    unsigned int red,green,blue;
    NSRange range;
    range.length = 2;
    
    range.location = 1;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&red];
    
    range.location = 3;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&green];
    
    range.location = 5;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&blue];
    
    return [UIColor colorWithRed:(float)(red/255.0f)green:(float)(green / 255.0f) blue:(float)(blue / 255.0f)alpha:1.0f];
}

// 根据配置文件获取颜色
- (UIColor*)getColorByConfig:(NSString*)pConfig
{
    UIColor* pRetColor = nil;
    NSString* pConfigDicPath = [[NSBundle mainBundle] pathForResource:@"QUCConfig" ofType:@"plist" inDirectory:@"qucsdkResources.bundle"];
    if (pConfigDicPath)
    {
        NSDictionary* pConfigDic = [NSDictionary dictionaryWithContentsOfFile:pConfigDicPath];
        if (pConfigDic) {
            NSString* pHexColor = [[[pConfigDic objectForKey:@"color"] objectForKey:pConfig] objectForKey:@"hex"];
            if (pHexColor) {
                pRetColor = [self getColorByHex:pHexColor];
            }
        }
    }
    
    return pRetColor;
}

// 根据配置文件获取Font
- (UIFont*)getFont:(NSString*)pFontConfg
{
    UIFont* pRetFont = nil;
    NSString* pConfigDicPath = [[NSBundle mainBundle] pathForResource:@"QUCConfig" ofType:@"plist" inDirectory:@"qucsdkResources.bundle"];
    if (pConfigDicPath)
    {
        NSDictionary* pConfigDic = [NSDictionary dictionaryWithContentsOfFile:pConfigDicPath];
        if (pConfigDic) {
            int nFontSize = [[[pConfigDic objectForKey:@"font"] objectForKey:pFontConfg] intValue];
            pRetFont = [UIFont systemFontOfSize:nFontSize];
        }
    }
    
    return pRetFont;
}

// 根据配置文件获取布局
- (int)getlayoutSize:(NSString*)pLayout
{
    int pLayoutSize = 0;
    NSString* pConfigDicPath = [[NSBundle mainBundle] pathForResource:@"QUCConfig" ofType:@"plist" inDirectory:@"qucsdkResources.bundle"];
    if (pConfigDicPath)
    {
        NSDictionary* pConfigDic = [NSDictionary dictionaryWithContentsOfFile:pConfigDicPath];
        if (pConfigDic) {
            pLayoutSize = [[[pConfigDic objectForKey:@"layout"] objectForKey:pLayout] intValue];
        }
    }
    return pLayoutSize;
    
}



@end
