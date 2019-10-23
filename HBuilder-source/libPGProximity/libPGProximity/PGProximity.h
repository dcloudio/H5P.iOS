//
//  PGProximity.h
//  PGProximity
//
//  Created by X on 13-8-6.
//  Copyright (c) 2013年 io.dcloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGPlugin.h"
#import "PGMethod.h"

@interface PGProximity : PGPlugin

@property(nonatomic, assign)BOOL started;
@property(nonatomic, retain)NSString* callBackID;

- (void)getCurrentProximity:(PGMethod*)command;
- (void)start:(PGMethod*)command;
- (void)stop:(PGMethod*)command;

@end
