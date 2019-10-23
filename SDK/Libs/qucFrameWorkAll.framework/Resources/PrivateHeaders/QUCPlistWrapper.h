//
//  QUCPlistWrapper.h
//  qucsdk
//
//  Created by simaopig on 15/3/12.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUCPlistWrapper : NSObject


+(NSMutableDictionary *)loadDataFromDocumentInDirectory:(NSString *)directoryName PlistFile:(NSString *)plistName CreateFileFlag:(BOOL)flag;


+(void)saveDataToDocumentInDirectory:(NSString *)directoryName PlistFile:(NSString *)plistName Data:(NSDictionary *)data;


+(void)removeInDirectory:(NSString *)directoryName PlistFile:(NSString *)plistName;

+(void)removeInDirectory:(NSString *)directoryName;
@end
