//
//  QUCConstants.h
//  qucsdkFramework
//
//  Created by simaopig on 14-6-28.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCConfig.h"

/* 可配置的参数 */
//注册是否需要激活
#define regIsNeedActive [[QUCConfig getInstance] getIntfBool:@"regIsNeedActive" DefVal:YES]
//请求用户中心接口是否全部仅使用HTTPS(默认为：使用https请求，当https请求失败后，使用http进行一次重试）
#define onlyUseHttps [[QUCConfig getInstance] getIntfBool:@"onlyUseHttps" DefVal:NO]
//请求用户中心接口，是否默认将返回结果进行加密（针对现有model、如果新增的model业务需要自行传递res_des值为QUCINTF_RES_MODE_DES）
#define onlyResModeDes [[QUCConfig getInstance] getIntfBool:@"onlyResModeDes" DefVal:YES]
//取头像的默认大小
#define headTypeDefault [[QUCConfig getInstance] getIntfStr:@"headTypeDefault" DefVal:@"s"]
//激活帐号之后的调转url
#define destUrlDefault [[QUCConfig getInstance] getIntfStr:@"destUrlDefault" DefVal:@"http://i.360.cn"]
//controller子类的名称
#define QUC_VC [[QUCConfig getInstance] getSubViewController]
//找回密码页的链接
#define findpwdWap [[QUCConfig getInstance] getIntfStr:@"findpwdWap" DefVal:@"http://i.360.cn/findpwdwap?client=app"]
//登录、注册等接口返回的用户信息字段
#define fieldsDefault [[QUCConfig getInstance] getIntfStr:@"fieldsDefault" DefVal:@"qid,username,nickname,loginemail,head_pic"]
//登录、找回密码接口传递的secType配置
#define secTypeDefault [[QUCConfig getInstance] getIntfStr:@"secTypeDefault" DefVal:@"bool"]
//用户中心Sdk版本
#define qucSdkVer [[QUCConfig getInstance] getSdkVer]
//用户中心存储suggest记录，及RSA公钥的文件目录
#define qucPlistDirectory @"QucManager"
//用户中心存储suggest记录的文件名称
#define qucLoginAccountPlist @"QucLoginAccount.plist"
//用户中心存储rsaPublicKey记录的文件名称
#define qucRsaPubKeyPlist @"QucRsaPubkey.plist"
//用户中心存储rsaPublicKey记录的字典key名称
#define qucRsaPubKeyName @"rsaPubKey"

// 是否支持海外手机号
#define qucSupportForeignNationalityMobile [[QUCConfig getInstance] getSupportForeignNationalityMobile]


/* 以下是不可配置的常量 */

typedef enum {
    QUC_ERROR_TYPE_SUCCESS = 0,
    QUCINTF_ACCOUNT_IS_EXIST = 1037,//帐号已存在，需要弹出qucAlertView
    QUCINTF_SMSCODE_WRONG = 1351,//手机短信校验码错误，回到前一个页面
    QUCINTF_BINDMOBILE_UNSET = 1660,//找回密码时，用户输入的不是手机号（例如纯数字且为用户名），当用户未绑定手机时会提示“您还没有绑定手机号”，将其映射为“手机号不合法”
    QUCINTF_PASSWORD_WRONG = 5009,//密码错误，需要根据errDetail来获取剩余次数
    QUCINTF_NEED_SHOW_CAPTCHA = 5010,//验证码错误，需要请求验证码
    QUCINTF_NEED_REFRESH_CAPTCHA = 5011,//验证码错误，需要请求验证码
    QUCINTF_LOGINEMAIL_IS_NOT_ACTIVATED = 20000,//用户尚未激活，需要根据errDetail来提醒激活
    QUCINTF_LOGINEMAIL_INACTIVE_NEED_USE_OLD_ACCOUNT = 20005,//用户该帐号尚未激活，需要使用原帐号进行登录
    QUCINTF_SENDACTIVEEMAIL_LIMIT = 1020801,//发送激活邮件达到最大值
    QUCINTF_DYNAMICPASSWORD_NEEDED = 155000, // 需要使用动态密码登录
}QUCINTF_ERROR_CODE;

typedef enum {
    QUCINTF_RSA_SUCCESS = 0,
    QUCINTF_RSA_PUBLICKEY_WRONG = 1021001,
}QUCINTF_RSA_ERROR_CODE;

typedef enum {
    QUC_ERROR_TYPE_INVALID_PARAMETER = -90000,//参数不正确
    QUC_ERROR_TYPE_INVALID_RESPONSE  = -90001,//返回格式不正确，例如未返回qt、qid等
    QUC_ERROR_TYPE_INVALID_JSONDATA  = -90002,//返回内容不是有效的json
    QUC_ERROR_TYPE_INVALID_NETWORK   = -90003,//网络异常
    QUC_ERROR_TYPE_CAPTCHA_NOTMATCH  = -90004,//不需要验证码
}QUCINTF_ERROR_TYPE;

typedef enum{
    QUCINTF_AUTOLOGIN_NO = 0,//不自动登录，Cookie有效期为一天
    QUCINTF_AUTOLOGIN_YES= 1,//自动登录，Cookie有效期视用户中心规定
}QUCINTF_AUTOLOGIN_TYPE;

#define QUCACCOUNT_TYPE_EMAIL    @"1"//帐号类型为邮箱
#define QUCACCOUNT_TYPE_MOBILE   @"2"//帐号类型为手机号
#define QUCACCOUNT_TYPE_USERNAME @"4"//帐号类型为用户名
#define QUCACCOUNT_TYPE_NICKNAME @"5"//帐号类型为昵称
#define QUCACCOUNT_TYPE_DEVICEID @"6"//帐号类型为设备号

#define QUCSENDSMS_CONDITION_ACCOUNT_EXIST @"1"//发送短信的场景：帐号存在时才发送
#define QUCSENDSMS_CONDITION_ACCOUNT_NOT_EXIST @"2"//发送短信的场景：帐号不存在时才发送
#define QUC_ACCOUNT_EMAIL_SUFFIX_ARRAY  @[@"qq.com",\
                                          @"163.com",\
                                          @"126.com",\
                                          @"sina.com",\
                                          @"vip.sina.com",\
                                          @"sina.cn",\
                                          @"hotmail.com",\
                                          @"gmail.com",\
                                          @"sohu.com",\
                                          @"139.com",\
                                          @"189.cn"]
