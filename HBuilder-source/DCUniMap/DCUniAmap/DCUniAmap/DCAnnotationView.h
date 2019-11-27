//
//  DCAnnotationView.h
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "DCMapCalloutView.h"
#import "DCMapMarker.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DCAnnotationViewDelegate <NSObject>

- (void)annotationCalloutViewTapped:(DCMapMarker *)marker;
- (void)annotationLabelTapped:(DCMapMarker *)marker;

@end


@interface DCAnnotationView : MAAnnotationView

@property (nonatomic, readonly) DCMapCalloutView *calloutView;

@property (nonatomic, weak) id<DCAnnotationViewDelegate> delegate;

- (void)updateInfo;

@end

NS_ASSUME_NONNULL_END
