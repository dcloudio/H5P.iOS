//
//  SAPPItemInfo+SAppShareController.m
//  StreamApp
//
//  Created by EICAPITAN on 16/1/28.
//  Copyright © 2016年 EICAPITAN. All rights reserved.
//

#import "PGShare.h"
#import "DCSAppShareView.h"
#import "PDRCommonString.h"
#import "PDRToolSystemEx.h"
#import "AFHTTPRequestOperationManager.h"


static DCSAppShareView* g_sappShareView = nil;


@implementation DCSAppShareView

+(id)Instance
{
    if (g_sappShareView == nil) {
        g_sappShareView = [[DCSAppShareView alloc] init];
    }
    return g_sappShareView;
}
    
#pragma mark makeShare

- (void)makeShareByType:(ESHARE_TYPE) shareType
{
    NSString* pSID = nil;
    NSMutableDictionary* pShareDic = [NSMutableDictionary dictionary];
    
    if(eCurShareType == ESHARE_SHARETYPE_APP)
    {
        switch (shareType) {
            case ESHARE_TYPE_QQ:
            {
                pSID = @"qq";
                if(m_shareContent)
                {
                    [pShareDic setObject:m_shareContent forKey:g_pdr_string_content ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                                  forKey:g_pdr_string_content ];
                }
                
                if(m_shareHref)
                {
                    [pShareDic setObject: m_shareHref forKey:g_pdr_string_href];
                }
                else{
                    [pShareDic setObject: m_shareHref?m_shareHref:[NSString
                                                                   stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                                  forKey:g_pdr_string_href];
                }
                
                [pShareDic setObject:@[[NSString
                                        stringWithFormat:@"file://%@",m_pIconPath]]
                              forKey:@"pictures" ];
                
            }
                break;
            case ESHARE_TYPE_WX:
            {
                pSID = @"weixin";
                [pShareDic setObject:m_pName forKey:g_pdr_string_title ];
                if(m_shareContent)
                {
                    [pShareDic setObject:m_shareContent forKey:g_pdr_string_content ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                                  forKey:g_pdr_string_content ];
                }
                
                if(m_shareHref)
                {
                    [pShareDic setObject: m_shareHref
                                  forKey:g_pdr_string_href];
                }
                else{
                    [pShareDic setObject: [NSString
                                           stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                                  forKey:g_pdr_string_href];
                }
                
                [pShareDic setObject:@{@"scene":@"WXSceneSession"} forKey:@"extra"];
            }
                break;
            case ESHARE_TYPE_PYQ:
            {
                pSID = @"weixin";
                
                if(m_shareHref)
                {
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\" %@",m_shareContent?m_shareContent:m_pName, m_shareHref]
                                  forKey:g_pdr_string_title ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧! http://m3w.cn/s/%@?__f=d3&__streamapp",m_pName, m_pAppid]
                                  forKey:g_pdr_string_title ];
                }
                
                
                [pShareDic setObject:@{@"scene":@"WXSceneTimeline"} forKey:@"extra"];
                
            }
                break;
            case ESHARE_TYPE_SINA:
            {
                pSID = @"sinaweibo";
                [pShareDic setObject:m_pName forKey:g_pdr_string_title ];
                if(m_shareHref)
                {
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\" %@",m_shareContent, m_shareHref]
                                  forKey:g_pdr_string_content ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧! http://m3w.cn/s/%@?__f=d3&__streamapp",m_pName, m_pAppid]
                                  forKey:g_pdr_string_content ];
                }
                
                [pShareDic setObject:@[[NSString
                                        stringWithFormat:@"file://%@",m_pIconPath]]
                              forKey:@"pictures" ];
                
            }
                break;
            case ESHARE_TYPE_SYSTEM:
            {
                pSID = @"System";
                if(m_shareContent)
                {
                    [pShareDic setObject:m_shareContent forKey:g_pdr_string_content ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                                  forKey:g_pdr_string_content ];
                }
                
                if(m_shareHref)
                {
                    [pShareDic setObject: m_shareHref
                                  forKey:g_pdr_string_href];
                }
                else{
                    [pShareDic setObject: [NSString
                                           stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                                  forKey:g_pdr_string_href];
                }

                [pShareDic setObject:@[[NSString
                                        stringWithFormat:@"file://%@",m_pIconPath]]
                              forKey:@"pictures" ];
            }
                break;
            default:
                break;
        }
    }
    else{
        
        switch (shareType) {
            case ESHARE_TYPE_QQ:
            {
                pSID = @"qq";
                if(m_shareContent)
                    [pShareDic setObject:m_shareContent forKey:g_pdr_string_content ];
                if(m_BrowserHref)
                    [pShareDic setObject: m_BrowserHref forKey:g_pdr_string_href];
                
                [pShareDic setObject:@[[NSString
                                        stringWithFormat:@"file://%@",m_pIconPath]]
                              forKey:@"pictures" ];
                
            }
                break;
            case ESHARE_TYPE_WX:
            {
                pSID = @"weixin";
                [pShareDic setObject:m_shareContent?m_shareContent:@"" forKey:g_pdr_string_title ];
                [pShareDic setObject:m_shareContent?m_shareContent:@"" forKey:g_pdr_string_content];
                [pShareDic setObject: m_BrowserHref
                                  forKey:g_pdr_string_href];
                
                [pShareDic setObject:@{@"scene":@"WXSceneSession"} forKey:@"extra"];
            }
                break;
            case ESHARE_TYPE_PYQ:
            {
                pSID = @"weixin";
                
                [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\" %@",m_shareContent?m_shareContent:@"", m_BrowserHref?m_BrowserHref:@""]
                                  forKey:g_pdr_string_title];
                [pShareDic setObject:@{@"scene":@"WXSceneTimeline"} forKey:@"extra"];
                
            }
                break;
            case ESHARE_TYPE_SINA:
            {
                pSID = @"sinaweibo";
                [pShareDic setObject:m_shareContent?m_shareContent:@"" forKey:g_pdr_string_title ];
                [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\" %@",m_shareContent?m_shareContent:@"", m_BrowserHref?m_BrowserHref:@""]
                                  forKey:g_pdr_string_content ];
            }
                break;
            case ESHARE_TYPE_SYSTEM:
            {
                pSID = @"System";
                if(m_shareContent)
                {
                    [pShareDic setObject:m_shareContent forKey:g_pdr_string_content ];
                }
                else{
                    [pShareDic setObject:[NSString
                                          stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                                  forKey:g_pdr_string_content ];
                }
                
                if(m_shareHref)
                {
                    [pShareDic setObject: m_shareHref
                                  forKey:g_pdr_string_href];
                }
                else{
                    [pShareDic setObject: [NSString
                                           stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                                  forKey:g_pdr_string_href];
                }
                
                [pShareDic setObject:@[[NSString
                                        stringWithFormat:@"file://%@",m_pIconPath]]
                              forKey:@"pictures" ];            }
                break;
        }

    }
    
    if (shareType != ESHARE_TYPE_SYSTEM) {
        PGShare* pShare = [pShareManager getShareObjectByType:pSID];
        if (pShare) {
            PGMethod* pMethod = [[PGMethod alloc] init];
            if ([pShare getToken] == nil) {
                [pShare authorize:pMethod];
            }
            
            if (pMethod) {
                pMethod.arguments = @[@"",@"", pShareDic];
            }
            [pShare send:pMethod];
        }
    }else{
        PGMethod* pMethod = [[PGMethod alloc] init];
        if (pMethod) {
            pMethod.arguments = @[@"", pShareDic];
        }
        [pShareManager sendWithSystem:pMethod];
    }
}


#pragma mark ActionSheet

- (void)showSharePanel:(UIView*)pParentView
                 Title:(NSString*)pTitle
               Content:(NSString*)content
                  Href:(NSString*)hRef
{
    if (pParentView == nil && pTitle == nil && content == nil && hRef == nil) {
        return;
    }
    
    eCurShareType = ESHARE_SHARETYPE_BROWSER;
    pActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    if (pActionSheet) {
        
        if (pShareManager == nil) {
            pShareManager = [[DCSAPPShareManager alloc] init];
        }
        if (pShareManager) {
            NSArray* pArray = [pShareManager getServices];
            for (PGShare* pShare in pArray) {
                NSDictionary* pDic = [pShare JSDict];
                if (pDic) {
                    if ([[pDic objectForKey:@"id"] compare:@"qq"] == NSOrderedSame) {
                        [pActionSheet addButtonWithTitle:@"QQ好友"];
                    }
                    
                    if ([[pDic objectForKey:@"id"] compare:@"weixin"] == NSOrderedSame) {
                        [pActionSheet addButtonWithTitle:@"微信好友"];
                        [pActionSheet addButtonWithTitle:@"微信朋友圈"];
                    }
                    
                    if ([[pDic objectForKey:@"id"] compare:@"sinaweibo"] == NSOrderedSame) {
                        [pActionSheet addButtonWithTitle:@"新浪微博"];
                    }
                }
            }
            [pActionSheet addButtonWithTitle:@"更多分享..."];
        }
        
        m_shareContent = [[NSString stringWithString:content] retain];
        m_BrowserHref = [[NSString stringWithString:hRef] retain];
        
        [pActionSheet showInView:pParentView];
        [pActionSheet release];
    }

}


- (void)showSharePanel:(UIView*)pParentView AppName:(NSString*)appname
                 AppID:(NSString*)pAppid IconPath:(NSString*)iconPath
                  Href:(NSString*)href content:(NSString*)description
{
    if (pParentView == nil && appname == nil && pAppid == nil && iconPath == nil) {
        return;
    }
    
    eCurShareType = ESHARE_SHARETYPE_APP;
    
    if(href)
        m_shareHref = [[NSString stringWithString:href] retain];
    
    if(description)
        m_shareContent = [[NSString stringWithString:description] retain];
    
    [self showSharePanel:pParentView AppName:appname AppID:pAppid IconPath:iconPath];
    
    if(href == nil || pAppid == nil)
        return;
    // 发起请求短地址
    NSString* pShortShareRequestURL = [NSString stringWithFormat:@"http://m3w.cn/sd/reg"];
    __block NSString* pStrPostBody = [NSString stringWithFormat:@"url=%@",[href URLEncodedStringEx]];

    NSMutableURLRequest* prequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pShortShareRequestURL]];
    if(prequest)
    {
        [prequest setHTTPMethod:@"POST"];
        [prequest setHTTPBody:[pStrPostBody dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    DCAFHTTPRequestOperationManager* manager = [DCAFHTTPRequestOperationManager manager];
    if(manager)
    {
        [manager POST:pShortShareRequestURL
           parameters:@{g_pdr_string_appid:pAppid,
                        @"deviceid":[PTDeviceInfo uniqueAppInstanceIdentifier]?[PTDeviceInfo uniqueAppInstanceIdentifier]:@"",
                        @"wap":href,
                        @"stream":pStrPostBody}
              success:^(DCAFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                  int i = 0;
                  if(responseObject && [responseObject isKindOfClass:[NSDictionary class]])
                  {
                      NSString* psURL = [responseObject objectForKey:@"surl"];
                      if(psURL)
                      {
                          m_shareHref = nil;
                          m_shareHref = [[NSString stringWithString:psURL] retain];
                      }
                  }
                  
              } failure:^(DCAFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
                  
              }];
    }
}

- (void)showSharePanel:(UIView*)pParentView AppName:(NSString*)appname AppID:(NSString*)pAppid IconPath:(NSString*)iconPath
{
    if (pParentView == nil && appname == nil && pAppid == nil && iconPath == nil) {
        return;
    }
    
    pActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    if (pActionSheet) {
        
        if (pShareManager == nil) {
            pShareManager = [[DCSAPPShareManager alloc] init];
        }
        if (pShareManager) {
            NSArray* pArray = [pShareManager getServices];
            for (PGShare* pShare in pArray) {
                NSDictionary* pDic = [pShare JSDict];
                if (pDic) {
//                    if ([[pDic objectForKey:@"id"] compare:@"qq"] == NSOrderedSame) {
//                        [pActionSheet addButtonWithTitle:@"QQ好友"];
//                    }
                    
                    if ([[pDic objectForKey:@"id"] compare:@"weixin"] == NSOrderedSame) {
                        [pActionSheet addButtonWithTitle:@"微信好友"];
                        [pActionSheet addButtonWithTitle:@"微信朋友圈"];
                    }
                    
//                    if ([[pDic objectForKey:@"id"] compare:@"sinaweibo"] == NSOrderedSame) {
//                        [pActionSheet addButtonWithTitle:@"新浪微博"];
//                    }
                }
            }
            [pActionSheet addButtonWithTitle:@"更多分享..."];
        }
        m_pAppid = [[NSString stringWithString:pAppid] retain];
        m_pName = [[NSString stringWithString:appname] retain];
        m_pIconPath = [[NSString stringWithString:iconPath] retain];
        
        [pActionSheet showInView:pParentView];
        [pActionSheet release];
    }
}
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* pButtonTitle = [pActionSheet buttonTitleAtIndex:buttonIndex];
    if ([pButtonTitle compare:@"QQ好友"] == NSOrderedSame) {
        [self makeShareByType:ESHARE_TYPE_QQ];
    }else if ([pButtonTitle compare:@"微信朋友圈"] == NSOrderedSame) {
        [self makeShareByType:ESHARE_TYPE_PYQ];
    }else if ([pButtonTitle compare:@"微信好友"] == NSOrderedSame) {
        [self makeShareByType:ESHARE_TYPE_WX];
    }else if ([pButtonTitle compare:@"新浪微博"] == NSOrderedSame) {
        [self makeShareByType:ESHARE_TYPE_SINA];
    }else if([pButtonTitle compare:@"更多分享..."] == NSOrderedSame){
        [self makeShareByType:ESHARE_TYPE_SYSTEM];
    }

}

- (void)dealloc
{
    if (m_pAppid)
        [m_pAppid release];
    if (m_pName)
        [m_pName release];
    if (m_pIconPath)
        [m_pIconPath release];

    if (pShareManager)
        [pShareManager release];
    
    [super dealloc];
}

@end
