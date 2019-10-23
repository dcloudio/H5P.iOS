//
//  NSString+random.h
//  qucsdk
//
//  Created by simaopig on 15/3/11.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (random)

/**
 *	@brief	从数字、大小写字母中，随机指定长度字符串
 *
 *	@param 	length 	长度
 */
+generateSimple:(NSInteger)length
;

/**
 *	@brief	从!——+93的Ascii中，随机指定长度字符串
 *
 *	@param 	length 	长度
 */
+generateFromAscii:(NSInteger)length;
@end
