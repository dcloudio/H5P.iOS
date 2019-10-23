//
//  QUCRegionItem.h
//  qucsdk
//
//  Created by huangxianshuai on 15/8/25.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QUCRegionItem : NSObject

@property (nonatomic, strong) NSString *pattern;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zone;

- (instancetype)initWithDic:(NSDictionary *)dic;

@end
