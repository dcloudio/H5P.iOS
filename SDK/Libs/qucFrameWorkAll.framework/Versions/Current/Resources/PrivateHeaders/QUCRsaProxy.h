//
//  QUCRsaProxy.h
//  qucsdk
//
//  Created by simaopig on 15/3/13.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    QUCRsaSucc          = 0,
    QUCRsaEncryptFailed = -1000,
    QUCRsaDecryptFailed = -1001,
}QucRsaStatus;

@interface QUCRsaProxy : NSObject

+(instancetype) shareInstance;

-(BOOL)upgradeRsaPublicKey:(NSString *)key Error:(NSError **)error;

-(NSString *)encryptByRsaPublicKey:(NSString *)sourcedata;

@end


@interface NSError (QucRsaProxy)
+ (NSError *) errorWithQucRsaStatus: (QucRsaStatus) status;
@end