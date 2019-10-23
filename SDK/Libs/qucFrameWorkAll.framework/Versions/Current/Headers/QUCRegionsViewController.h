//
//  QUCRegionsViewController.h
//  qucsdk
//
//  Created by huangxianshuai on 15/5/25.
//  Copyright (c) 2015年 Qihoo360. All rights reserved.
//

#import <qucFrameWorkAll/qucFrameWorkAll.h>
#import "QUCRegionsModel.h"

typedef void(^UpdateRegionLabelBlcok)(QUCRegionItem *regionItem);

@interface QUCRegionsViewController : QUCBasicViewController

@property (nonatomic, strong) UpdateRegionLabelBlcok updatetegionLabelBlock;

@end
