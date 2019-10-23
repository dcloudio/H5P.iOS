//
//  DCUniUtility.h
//  libWeex
//
//  Created by XHY on 2019/5/29.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const dc_uni_callback_type;
extern NSString *const dc_uni_success;
extern NSString *const dc_uni_fail;
extern NSString *const dc_uni_code;
extern NSString *const dc_uni_message;

/**
 错误码
 */
typedef NS_ENUM(NSInteger,DCUniPluginErrorCode) {
    DCUniPluginErrorInner = -100,                   /**< 业务内部错误 */
    DCUniPluginErrorUnknown = -99,                  /**< 未知错误 */
    DCUniPluginErrorAuthDenied = -10,               /**< 授权失败 */
    DCUniPluginErrorNoInstall = -8,                 /**< 客户端未安装 */
    DCUniPluginErrorConfig = -7,                    /**< 业务参数配置缺失 */
    DCUniPluginErrorNet = -6,                       /**< 网络错误 */
    DCUniPluginErrorIO = -5,                        /**< IO错误 */
    DCUniPluginErrorFileNotFound = -4,              /**< 文件不存在 */
    DCUniPluginErrorNotSupport = -3,                /**< 此功能不支持 */
    DCUniPluginErrorUserCancel = -2,                /**< 用户取消 */
    DCUniPluginErrorInvalidArgument = -1,           /**< 无效的参数 */
    DCUniPluginOK = 0,                              /**< 成功 */
    DCUniPluginErrorFileExist,                      /**< 文件存在 */
    DCUniPluginErrorFileCreateFail,                 /**< 文件创建失败 */
    DCUniPluginErrorZipFail,                        /**< 压缩失败 */
    DCUniPluginErrorUnZipFail,                      /**< 解压失败 */
    DCUniPluginErrorNotAllowWrite,                  /**< 不允许写 */
    DCUniPluginErrorNotAllowRead,                   /**< 不允许读 */
    DCUniPluginErrorBusy,                           /**< 上次调用未完成，完成后再次调用 */
    DCUniPluginErrorNotPermission                   /**< 没有权限 */
};

@interface DCUniCallbackUtility : NSObject


/**
 构建成功回调数据（NSDictionary）

 @return 构建后的成功回调数据（NSDictionary）
 */
+ (NSDictionary *)success;

/**
 构建成功回调数据（NSDictionary）
 
 @param data 回调数据
 @return 构建后的成功回调数据（NSDictionary）
 */
+ (NSDictionary *)successResult:(NSDictionary * _Nullable)data;

/**
 构建错误回调数据（NSDictionary）
 
 @param errorCode 错误码（DCUniPluginErrorCode）
 @return 构建后的错误回调数据（NSDictionary）
 */
+ (NSDictionary *)errorResult:(DCUniPluginErrorCode)errorCode;

/**
 构建错误回调数据（NSDictionary）
 
 @param errorCode 错误码（DCUniPluginErrorCode）
 @param errorMessage 错误信息（不传则使用默认描述）
 @return 构建后的错误回调数据（NSDictionary）
 */
+ (NSDictionary *)errorResult:(DCUniPluginErrorCode)errorCode
                 errorMessage:(NSString * _Nullable)errorMessage;

/**
 第三方SDK报错时 构建错误信息
 [%模块名称%+%第三方SDK名称%: %第三方SDK错误码%]%错误描述信息%
 如 “[OAuth微信:-1]未知错误，...”
 @param pluginName 功能模块名称
 @param SDKName 第三方SDK名称
 @param SDKErrorCode 第三方SDK报的 error code
 @param errmsg 第三方SDK报的错误描述
 @return 构建后的错误信息
 */
+ (NSString *)errorMessageWithPluginName:(NSString * _Nullable)pluginName
                                 SDKName:(NSString * _Nullable)SDKName
                            SDKErrorCode:(int)SDKErrorCode
                         SDKErrorMessage:(NSString * _Nullable)errmsg;

@end

NS_ASSUME_NONNULL_END
