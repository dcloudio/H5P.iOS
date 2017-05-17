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
    ESHARE_TYPE_QQ
}ESHARE_TYPE;


@interface DCSAppShareView : UIView <UIActionSheetDelegate>
{
    UIActionSheet* pActionSheet;
    DCSAPPShareManager *pShareManager;
    NSString* m_pName;
    NSString* m_pAppid;
    NSString* m_pIconPath;
}

+(id)Instance;

- (void)showSharePanel:(UIView*)pParendView AppName:(NSString*)appname AppID:(NSString*)pAppid IconPath:(NSString*)iconPath;
@end
