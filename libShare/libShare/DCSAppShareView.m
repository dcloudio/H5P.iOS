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
    switch (shareType) {
        case ESHARE_TYPE_QQ:
        {
            pSID = @"qq";
            [pShareDic setObject:[NSString
                                  stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                          forKey:g_pdr_string_content ];
            [pShareDic setObject: [NSString
                                   stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                          forKey:g_pdr_string_href];
            [pShareDic setObject:@[[NSString
                                    stringWithFormat:@"file://%@",m_pIconPath]]
                          forKey:@"pictures" ];
            
        }
            break;
        case ESHARE_TYPE_WX:
        {
            pSID = @"weixin";
            [pShareDic setObject:m_pName forKey:g_pdr_string_title ];
            [pShareDic setObject:[NSString
                                  stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧!",m_pName]
                          forKey:g_pdr_string_content ];
            [pShareDic setObject: [NSString
                                   stringWithFormat:@"http://m3w.cn/s/%@?__f=d3&__streamapp",m_pAppid]
                          forKey:g_pdr_string_href];
            [pShareDic setObject:@{@"scene":@"WXSceneSession"} forKey:@"extra"];
        }
            break;
        case ESHARE_TYPE_PYQ:
        {
            pSID = @"weixin";
            [pShareDic setObject:[NSString
                                  stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧! http://m3w.cn/s/%@?__f=d3&__streamapp",m_pName, m_pAppid]
                          forKey:g_pdr_string_title ];
            
            [pShareDic setObject:@{@"scene":@"WXSceneTimeline"} forKey:@"extra"];
            
        }
            break;
        case ESHARE_TYPE_SINA:
        {
            pSID = @"sinaweibo";
            [pShareDic setObject:m_pName forKey:g_pdr_string_title ];
            [pShareDic setObject:[NSString
                                  stringWithFormat:@"\"%@\"是个很赞的App，如果你有流应用引擎还能省流量秒装，快来体验吧! http://m3w.cn/s/%@?__f=d3&__streamapp",m_pName, m_pAppid]
                          forKey:g_pdr_string_content ];
            [pShareDic setObject:@[[NSString
                                    stringWithFormat:@"file://%@",m_pIconPath]]
                          forKey:@"pictures" ];
            
        }
            break;
        default:
            break;
    }
    
    
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
}


#pragma mark ActionSheet

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
