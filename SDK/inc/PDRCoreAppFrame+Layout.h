//
//  PDRCoreappFrame+Layout.h
//  libPDRCore
//
//  Created by dcloud on 2019/4/27.
//  Copyright © 2019 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDRCoreAppFrame.h"
#import "NWindowOptionsParse.h"

NS_ASSUME_NONNULL_BEGIN


@interface PDRCoreAppFrame(Layout)

- (PGNWindowOptionsParse*)layoutNView:(PDRNView*)pView;
- (PGNWindowOptionsParse*)layoutApplyOptions;
- (PGNWindowOptionsParse*)layoutApplyOptions:(BOOL)force;
- (void)layoutChildren;
- (void)NWindowShowSetOptionAnimationDestLayoutRect:(CGRect)destLayoutRect;
- (CGRect)getContentRect;
- (void)layoutRefreshContorl;
- (void)layoutBounceBottomLayer;
- (void)layoutBounceTopLayer;
- (BOOL)isTitleNViewAppendStatusbarHeight;
@end

NS_ASSUME_NONNULL_END
