//
//  QUCConfig.h
//  qucsdk
//
//  Created by simaopig on 14/10/30.
//  Copyright (c) 2014年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUCConfig : NSObject
+(QUCConfig *) getInstance;
-(NSString *) getSdkVer;
-(CGFloat)getLayout:(NSString *)key;
-(UIColor *)getColor:(NSString *)key;
-(UIFont *)getFont:(NSString *)key;
-(NSString *)getIntfStr:(NSString *)key DefVal:(NSString *)val;
-(BOOL)getIntfBool:(NSString *)key DefVal:(BOOL)val;
-(NSDictionary *)getSubViewController;

- (BOOL)getSupportForeignNationalityMobile;
@end
