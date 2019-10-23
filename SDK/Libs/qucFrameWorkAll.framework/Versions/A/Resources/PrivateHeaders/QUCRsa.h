//
//  QUCRsa.h
//  qucsdk
//
//  Created by simaopig on 15/3/9.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/rsa.h>
#import <openssl/pem.h>
#import <openssl/err.h>

typedef enum {
    RsaKeyTypePublic,
    RsaKeyTypePrivate
}RsaKeyType;

@interface QUCRsa : NSObject{

}


/**
 *	@brief	获取QucRsa单例对象，仅支持RSA_PKCS1_PADDING
 *
 *	@param 	type 用于描述是否在加密后或解密前进行base64操作
 *
 *	@return	QucRsa instance
 */
+ (instancetype)shareInstance;


/**
 *	@brief	使用公钥对数据进行加密
 *
 *	@param 	content 待加密内容
 *	@param 	key 	Rsa公钥
 *
 *	@return	加密后的内容
 */
- (NSString *) encryptByRsa:(NSString *)content WithPublicKey:(NSString *)key;

/**
 *	@brief	使用公钥对数据进行解密
 *
 *	@param 	content 待解密内容
 *	@param 	key 	Rsa公钥
 *
 *	@return	解密后的内容
 */
- (NSString *) decryptByRsa:(NSString *)content WithPublicKey:(NSString *)key;


/**
 *	@brief	使用私钥对数据进行加密
 *
 *	@param 	content 待加密内容
 *	@param 	key 	Rsa私钥
 *
 *	@return	加密后的内容
 */
- (NSString *) encryptByRsa:(NSString *)content WithPrivateKey:(NSString *)key;

/**
 *	@brief	使用私钥对数据进行解密
 *
 *	@param 	content 待解密内容
 *	@param 	key 	Rsa私钥
 *
 *	@return	解密后的内容
 */
- (NSString *) decryptByRsa:(NSString *)content WithPrivateKey:(NSString *)key;

/**
 *	@brief	通过公钥pem文件路径，对内容进行加密
 *
 *	@param 	content 待加密内容
 *	@param 	path 	公钥pem路径
 *
 *	@return	加密后的内容
 */
- (NSString *) encryptByRsa:(NSString *)content WithPublicPemPath:(NSString *)path;


/**
 *	@brief	通过公钥pem文件路径，对内容进行解密
 *
 *	@param 	content 待解密内容
 *	@param 	path 	公钥pem路径
 *
 *	@return	解密后的内容
 */
- (NSString *) decryptByRsa:(NSString *)content WithPublicPemPath:(NSString *)path;


/**
 *	@brief	通过私钥pem文件路径，对内容进行加密
 *
 *	@param 	content 待加密内容
 *	@param 	path 	私钥pem路径
 *
 *	@return	加密后的内容
 */
- (NSString *) encryptByRsa:(NSString *)content WithPrivatePemPath:(NSString *)path;


/**
 *	@brief	通过私钥pem文件路径，对内容进行解密
 *
 *	@param 	content 待解密内容
 *	@param 	path 	私钥pem路径
 *
 *	@return	解密后的内容
 */
- (NSString *) decryptByRsa:(NSString *)content WithPrivatePemPath:(NSString *)path;


@end