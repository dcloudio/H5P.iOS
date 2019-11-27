//
//  DCMapCalloutView.h
//  AMapImp
//
//  Created by XHY on 2019/4/13.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMapMarker.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCMapCalloutView : UIView

@property (nonatomic, weak) DCMapMarker *annotation;

@end

NS_ASSUME_NONNULL_END
