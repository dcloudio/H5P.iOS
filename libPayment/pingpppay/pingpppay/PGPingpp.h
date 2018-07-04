//
//  PGPingpp.h
//  HBuilder-PGPingpp
//
//  Created by afon on 15/3/6.
//  Copyright (c) 2015年 Pingplusplus. All rights reserved.
//

#import "PGPlatby.h"

@interface PGPingpp : PGPlatby {
}

@property(nonatomic, copy) NSString *callBackID;
@property(nonatomic, copy) NSDictionary *chargeDict;
- (void)request:(PGMethod*)command;

@end
