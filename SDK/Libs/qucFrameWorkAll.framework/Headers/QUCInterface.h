//
//  QUCInterface.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-25.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCHTTPRequest.h"

typedef enum{
    QUCINTF_PROTOCOL_HTTPS = 0,//以HTTPS协议发送请求
    QUCINTF_PROTOCOL_HTTP  = 1,//以HTTP协议发送请求
}QUCIntfProtocol;

typedef enum {
	QUCINTF_REQUEST_METHOD_GET  = 0,//Get方式发送请求
    QUCINTF_REQUEST_METHOD_POST = 1,//POST方式发送请求
}QUCIntfRequestMethod;

typedef enum{
    QUCINTF_RES_MODE_JSON = 0,//要求数据以JSON格式返回
    QUCINTF_RES_MODE_DES  = 1,//要求数据以对JSON进行DES加密后返回
}QUCIntfResMod;

typedef enum{
    QUCINTF_AUTOLOGIN_QTERRDESC_NO = 0,//自动登录接口，不希望返回QT失效的详细信息
    QUCIntf_AUTOLOGIN_QTERRDESC_YES= 1,//自动登录接口，希望返回QT失效的详细信息
}QUCIntfAutoLoginQTErrdesc;

/**
 *	@brief	请求用户中心服务端的封装类，可以请求任何服务端接口
 */
@interface QUCInterface : NSObject
/**
 *	@brief	返回QucInterFace对象，如果没有初始化，就返回nil
 *
 *	@return	QUCInterface instance
 */
+(instancetype) sharedQUCInterface;

/**
 *	@brief	根据参数初始化QucInterFace对象，设置业务信息
 *
 *  @param  from    用户中心为业务分配的标识信息
 *	@param 	mid 	业务APPMid信息
 *  @param  signKey 用户中心为业务分配的签名私钥信息
 *  @param  desKey  用户中心为业务分配的DES加密私钥信息
 *
 *	@return	QUCInterface instance
 */
+(instancetype) sharedQUCInterfaceWithSrc:(NSString *)from
                                      Mid:(NSString *)mid
                                  SignKey:(NSString *)signKey
                                   DesKey:(NSString *)desKey;

/**
 *	@brief	请求用户中心接口，返回json项
 *
 *	@param 	method 	QUCINTF_REQUEST_METHOD_GET or QUCINTF_REQUEST_METHOD_POST
 *	@param 	parameters 	参数字典
 *	@param 	cookie 	QT Cookie信息 [NSString stringWithFormat:@"Q=%@; T=%@",Q,T]
 *	@param 	progressBlock 	请求过程中回调
 *	@param 	completeBlock 	请求结束后回调
 */
-(void) sendRequestWIthMethod:(QUCIntfRequestMethod)method
                   parameters:(NSMutableDictionary *)parameters
                       cookie:(NSString *)cookie
                     progress:(QUCHTTPRequestProcessHandler)progressBlock
                     complete:(QUCHTTPRequestCompletionHandler)completeBlock;

/**
 *	@brief	请求用户中心接口，返回data（例如请求验证码接口，务必使用此方法）
 *
 *	@param 	method 	QUCINTF_REQUEST_METHOD_GET or QUCINTF_REQUEST_METHOD_POST
 *	@param 	parameters 	参数字典
 *	@param 	cookie 	QT Cookie信息 [NSString stringWithFormat:@"Q=%@; T=%@",Q,T]
 *	@param 	progressBlock 	请求过程中回调
 *	@param 	completeBlock 	请求结束后回调
 */
-(void) sendBytesRequestWIthMethod:(QUCIntfRequestMethod)method
                        parameters:(NSMutableDictionary *)parameters
                            cookie:(NSString *)cookie
                          progress:(QUCHTTPRequestProcessHandler)progressBlock
                          complete:(QUCHTTPRequestCompletionHandler)completeBlock;

/**
 *	@brief	根据业务传递参数及协议，生成用户中心接口的URL（便于业务方自行发送HTTP请求）
 *
 *	@param 	parameters 	请求URL的参数字典，系统会根据initWithConf得到的信息增加from等参数
 *	@param 	protocol 	QUCINTF_PROTOCOL_HTTP or QUCINTF_PROTOCOL_HTTPS
 *
 *	@return	URL
 */
-(NSString *) getUrl:(NSMutableDictionary *)parameters
            Protocol:(QUCIntfProtocol)protocol;

/**
 *	@brief	获取Json字典，可根据desFlag来决定是否先进行des解密
 *          需要进行try catch，防止返回非json格式
 *	@param 	response 	用户中心接口返回的全部内容
 *	@param 	desFlag 	标志是否需要先进行des解密
 *
 *	@return	jsonDict
 */
-(NSDictionary *) getJsonDict:(id)response NeedDes:(BOOL)desFlag;

/**
 *	@brief	获取含Q key及T key的字典
 *
 *	@param 	responseCookie 	接口请求complete后返回的responseCookie头
 *
 *	@return	[NSDictionary dictionaryWithObjectsAndKeys:cookieQ,@"Q",cookieT,@"T",nil]
 */
+(NSDictionary *) getQTDict:(NSDictionary *)responseCookie;

/**
 *	@brief	获取QT组合后的字符串
 *
 *	@param 	responseCookie 	接口请求complete后返回的responseCookie头
 *
 *	@return	[NSString stringWithFormat:@"Q=%@; T=%@",Q,T] or nil
 */
+(NSString *) getQTStr:(NSDictionary *)responseCookie;

/**
 *	@brief	获取当前APP Version信息
 *
 *	@return	NSString
 */
+(NSString *) getVersion;

/**
 *	@brief	获取默认的vtGuid，为当前时间戳
 *
 *	@return	NSString
 */
+(NSString *) getDefVtGuid;

/**
 *  删除之前网络请求过程中NSHTTPCookieStorage存储的QT Cookie
 */
+(void)deleteHistoryQTCookie;
@end
