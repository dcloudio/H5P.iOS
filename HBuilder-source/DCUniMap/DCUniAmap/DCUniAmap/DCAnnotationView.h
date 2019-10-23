//
//  DCAnnotationView.h
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "DCMapCalloutView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCAnnotationView : MAAnnotationView

@property (nonatomic, readonly) DCMapCalloutView *calloutView;

- (void)updateInfo;

@end

NS_ASSUME_NONNULL_END
