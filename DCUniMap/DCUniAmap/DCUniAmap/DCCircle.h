//
//  DCCircle.h
//  AMapImp
//
//  Created by XHY on 2019/4/23.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCCircle : MACircle

@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *fillColor;
@property (nonatomic, assign) CGFloat strokeWidth;

@end

NS_ASSUME_NONNULL_END
