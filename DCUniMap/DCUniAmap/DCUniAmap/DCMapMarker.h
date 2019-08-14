//
//  DCMapMarker.h
//  AMapImp
//
//  Created by XHY on 2019/4/11.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "DCMapCalloutModel.h"
#import "WXConvert+DCMap.h"
#import "DCMapLabelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCMapMarker : MAAnimatedAnnotation

@property (nonatomic, assign) NSInteger _id;
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) NSInteger zIndex;
@property (nonatomic, assign) NSInteger rotate;
@property (nonatomic, assign) CGPoint anchor;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, strong) DCMapCalloutModel *callout;
@property (nonatomic, strong) DCMapLabelModel *labelModel;

@end

NS_ASSUME_NONNULL_END
