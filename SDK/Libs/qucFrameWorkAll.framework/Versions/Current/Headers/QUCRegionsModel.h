//
//  QUCRegionsModel.h
//  qucsdk
//
//  Created by huangxianshuai on 15/5/25.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QUCRegionItem.h"

@interface QUCRegionsModel : NSObject

@property (nonatomic, strong) NSArray *regions;

+ (instancetype)shareInstance;
- (void)updateRegionsWithDataArr:(NSArray *)arr;

@end
