//
//  UIView+PGPushIAP.h
//  HBuilder-Integrate
//
//  Created by MacPro on 15-10-22.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import "PGPay.h"
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface PGPayIAP : PGPlatby <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@end
