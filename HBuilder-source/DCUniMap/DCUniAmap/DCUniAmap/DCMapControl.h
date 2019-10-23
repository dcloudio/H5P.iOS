//
//  DCMapControl.h
//  DCUniAmap
//
//  Created by XHY on 2019/5/31.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCMapPosition.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCMapControl : UIButton

@property (nonatomic, assign) NSInteger _id;
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, assign) BOOL clickable;
@property (nonatomic, strong) DCMapPosition *position;

@end

NS_ASSUME_NONNULL_END
