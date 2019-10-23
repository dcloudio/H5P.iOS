//
//  NSDictionary+DCExtend.m
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "NSDictionary+DCExtend.h"

@implementation NSDictionary (DCExtend)

- (id)dc_safeObjectForKey:(id)aKey
{
    id object = [self objectForKey:aKey];
    if (object == [NSNull null]) {
        return nil;
    }
    return object;
}

@end

@implementation NSMutableDictionary (WXMap)

- (void)dc_safeSetObject:(id)anObject forKey:(id)aKey
{
    if(!aKey) {
        return;
    }
    if(anObject) {
        [self setObject:anObject forKey:aKey];
    }
}

- (void)dc_safeRemoveObjectForKey:(id)aKey
{
    if(aKey) {
        [self removeObjectForKey:aKey];
    }
}

@end
