//
//  QUCUserModel.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-30.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//
#import <Foundation/Foundation.h>

/**
 *	@brief	用户信息Model
 */
@interface QUCUserModel : NSObject


/**
 *	@brief	用户输入的帐号，用于增加suggest，以及业务方显示当前登录用户信息使用
 */
@property(nonatomic,strong) NSString* inputAccount;
@property(nonatomic,strong) NSString* qid;
@property(nonatomic,strong) NSString* userName;
@property(nonatomic,strong) NSString* nickName;
@property(nonatomic,strong) NSString* loginEmail;
@property(nonatomic,strong) NSString* Q;
@property(nonatomic,strong) NSString* T;

@property(nonatomic,assign) BOOL headFlag;
@property(nonatomic,strong) NSString* headPic;
@property(nonatomic,assign) BOOL loginEmailStatus;
@property(nonatomic,assign) BOOL secEmailStatus;
@property(nonatomic,assign) BOOL secMobileStatus;
@property(nonatomic,strong) NSString* secEmail;
@property(nonatomic,strong) NSString* secMobileZone;
@property(nonatomic,strong) NSString* secMobileNumber;
@property(nonatomic,strong) NSDictionary *orgInfo;

/**
 *	@brief	实例化用户信息类
 *
 *	@param 	inputAccount 	用户输入的帐号，如果自动登录等场景返回用户信息，则传nil
 *	@param 	userDict 	用户中心返回的user数据
 *	@param 	qtDict 	用户中心返回的qtDict
 *
 *	@return	QUCUserModel
 */
-(QUCUserModel *) initWithInputAccount:(NSString *)inputAccount
                              UserInfo:(NSDictionary *)userDict
                                    QT:(NSDictionary *)qtDict;

/**
 *	@brief	获取已经登录过的用户列表，用于初始化suggest数据
 *
 *	@return NSMutableDictionary
 */
+(NSMutableDictionary *)getInputAccounts;

/**
 *	@brief	根据邮箱获取其主站地址
 *
 *	@param 	email 	邮箱
 *
 *	@return	NSString
 */
+(NSString *)getMailHostUrl:(NSString *)email;

@end
