//
//  DCModel.h
//  DCModel <https://github.com/ibireme/DCModel>
//
//  Created by ibireme on 15/5/10.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

#if __has_include(<DCModel/DCModel.h>)
FOUNDATION_EXPORT double DCModelVersionNumber;
FOUNDATION_EXPORT const unsigned char DCModelVersionString[];
#import <DCModel/NSObject+DCModel.h>
#import <DCModel/DCClassInfo.h>
#else
#import "NSObject+DCModel.h"
#import "DCClassInfo.h"
#endif
