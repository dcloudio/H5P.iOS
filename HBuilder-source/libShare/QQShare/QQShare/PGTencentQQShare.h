//
//  QQShare.h
//  QQShare
//
//  Created by X on 15/3/17.
//  Copyright (c) 2015年 io.dcloud.QQShare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGShare.h"
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>

@interface PGTencentQQShare : PGShare<QQApiInterfaceDelegate> {
    TencentOAuth* _tencentOAuth;
    NSObject* temp_send_delegate;
    SEL onSendSuccessCallback;
    SEL onSendFailureCallback;
}

- (NSString*)getToken;

- (BOOL)authorizeWithURL:(NSString*)url
                delegate:(NSObject*)delegate
               onSuccess:(SEL)successCallback
               onFailure:(SEL)failureCallback;
- (BOOL)logOut;
- (BOOL)send:(PGShareMessage*)msg
    delegate:(id)delegate
   onSuccess:(SEL)successCallback
   onFailure:(SEL)failureCallback;

@end
