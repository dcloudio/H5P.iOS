//
//  NSString+URL.h
//  App360Contacts
//
//  Created by Jiang Zhao on 12-6-21.
//  Copyright (c) 2012年 qihoo 360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URL)

- (NSString *)urlEncoded;
- (NSString *)ucdesFormat:(NSString *) key;
- (NSString *)undesFormat:(NSString *) key;
@end

