//
//  NSArray+DCExtend.m
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import "NSArray+DCExtend.h"

@implementation NSArray (DCExtend)

- (id)dc_safeObjectForKey:(NSInteger)index {
    if (index < self.count) {
        id object = self[index];
        if (object == [NSNull null]) {
            return nil;
        }
        return object;
    }
    return nil;
}

@end


@implementation NSMutableArray (DCExtend)

- (void)dc_safeAddObject:(id)object {
    if (object) {
        [self addObject:object];
    }
}

@end
