//
//  UIColor+QUC.h
//  qucsdk
//
//  Created by simaopig on 14/10/31.
//  Copyright (c) 2014年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor (QUC)

+ (UIColor *) colorWithHexString:(NSString *)hex Alpha:(CGFloat)alpha;
+ (UIColor *) colorWithHexValue: (NSInteger) hex Alpha:(CGFloat)alpha;

@end
