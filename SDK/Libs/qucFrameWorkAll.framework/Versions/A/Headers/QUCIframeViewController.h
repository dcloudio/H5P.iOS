//
//  QUCFindPwdIframeViewController.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-2.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import "QUCBasicViewController.h"
@class QUCIframeView;

/**
 *	@brief	此VC加载了webView，在webView中打开的页面\n
 *          其dict应包含url及navTitle key
 */
@interface QUCIframeViewController : QUCBasicViewController<UIWebViewDelegate>

@property (nonatomic,strong) QUCIframeView *iframeView;
@end
