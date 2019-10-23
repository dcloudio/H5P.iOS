//
//  MiPassport.h
//  MiPassportDemo
//
//  Created by 李 业 on 13-7-11.
//  Copyright (c) 2013年 李 业. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPAuthorizeDialog.h"

typedef enum {
    MPPreferLocaleOfSystem = 0,
    MPPreferLocaleOfApp
} MPPreferredLocaleSource;

@protocol MPSessionDelegate;

@interface MiPassport : NSObject

@property (nonatomic, strong) NSString* appId;
@property (nonatomic, strong) NSString* accessToken;
@property (nonatomic, strong) NSString* tokenType;
@property (nonatomic, assign) id<MPSessionDelegate> sessionDelegate;
@property (nonatomic, strong) NSString *ssoCallbackScheme;
@property (nonatomic, strong) NSDate* expirationDate;
@property (nonatomic, strong) NSArray *permissions;
@property (nonatomic, strong) NSString *encryptAlgorithm;
@property (nonatomic, strong) NSString *encryptKey;
@property (nonatomic, assign) MPPreferredLocaleSource preferredLocaleSource;

- (id)initWithAppId:(NSString *)appId
        redirectUrl:(NSString *)redirectUrl
        andDelegate:(id<MPSessionDelegate>)delegate;

- (void)loginWithPermissions:(NSArray *)permissions;
- (void)applyPassCodeWithPermissions:(NSArray *)permissions;

- (void)logOut;

- (MPRequest *)requestWithURL:(NSString *)url
                       params:(NSMutableDictionary *)params
                   httpMethod:(NSString *)httpMethod
                     delegate:(id<MPRequestDelegate>)_delegate;

- (BOOL)handleOpenURL:(NSURL *)url;
@end


/**
 * Your application should implement this delegate to receive session callbacks.
 */
@protocol MPSessionDelegate <NSObject>

@optional

/**
 * Called when the user successfully logged in.
 */
- (void)passportDidLogin:(MiPassport *)passport;
/**
 * Called when the user failed to log in.
 */
- (void)passport:(MiPassport *)passport failedWithError:(NSError *)error;

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)passportDidCancel:(MiPassport *)passport;

/**
 * Called when the user logged out.
 */
- (void)passportDidLogout:(MiPassport *)passport;

/**
 * Called when the user get code.
 */
- (void)passport:(MiPassport *)passport didGetCode:(NSString *)code;

/**
 * Called when access token expired.
 */
- (void)passport:(MiPassport *)passport accessTokenInvalidOrExpired:(NSError *)error;
@end
