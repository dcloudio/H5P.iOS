//
//  SAPPItemInfo+SAppShareController.h
//  StreamApp
//
//  Created by EICAPITAN on 16/1/28.
//  Copyright © 2016年 EICAPITAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCSAPPShareManager.h"


typedef enum {
    ESHARE_TYPE_PYQ,
    ESHARE_TYPE_WX,
    ESHARE_TYPE_SINA,
    ESHARE_TYPE_QQ,
    ESHARE_TYPE_SYSTEM
}ESHARE_TYPE;

typedef enum  {
    ESHARE_SHARETYPE_APP,
    ESHARE_SHARETYPE_BROWSER
}ESHARE_SHARETYPE;


@interface DCSAppShareView : UIView <UIActionSheetDelegate>
{
    UIActionSheet* pActionSheet;
    DCSAPPShareManager *pShareManager;
    NSString* m_pName;
    NSString* m_pAppid;
    NSString* m_shareHref;
    NSString* m_shareContent;
    NSString* m_pIconPath;
    NSString* m_BrowserHref;
    ESHARE_SHARETYPE eCurShareType;
}

+(id)Instance;

- (void)showSharePanel:(UIView*)pParendView AppName:(NSString*)appname AppID:(NSString*)pAppid IconPath:(NSString*)iconPath;
- (void)showSharePanel:(UIView*)pParendView AppName:(NSString*)appname
                 AppID:(NSString*)pAppid IconPath:(NSString*)iconPath
                  Href:(NSString*)href content:(NSString*)description;

- (void)showSharePanel:(UIView*)pParentView Title:(NSString*)pTitle Content:(NSString*)content Href:(NSString*)hRef;
@end
