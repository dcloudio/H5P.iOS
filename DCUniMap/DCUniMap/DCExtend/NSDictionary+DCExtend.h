//
//  NSDictionary+DCExtend.h
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (DCExtend)

- (id)dc_safeObjectForKey:(id)aKey;

@end

@interface NSMutableDictionary (DCExtend)

- (void)dc_safeSetObject:(id)anObject forKey:(id)aKey;

- (void)dc_safeRemoveObjectForKey:(id)aKey;

@end

NS_ASSUME_NONNULL_END
