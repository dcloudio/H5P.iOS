//
//  NSArray+DCExtend.h
//  libWeexMap
//
//  Created by XHY on 2019/4/10.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (DCExtend)

- (id)dc_safeObjectForKey:(NSInteger)index;

@end

@interface NSMutableArray (DCExtend)

- (void)dc_safeAddObject:(id)object;

@end

NS_ASSUME_NONNULL_END
