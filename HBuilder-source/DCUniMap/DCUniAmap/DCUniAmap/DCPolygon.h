//
//  DCPolygon.h
//  AMapImp
//
//  Created by XHY on 2019/4/22.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCPolygon : MAPolygon

@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, copy) NSString *strokeColor;
@property (nonatomic, copy) NSString *fillColor;
@property (nonatomic, assign) NSInteger zIndex;

@end

NS_ASSUME_NONNULL_END
