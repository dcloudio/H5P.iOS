//
//  DCViewControllerShowHUDProgress.m
//  DemoProject
//
//  Created by nearwmy on 2018/6/19.
//  Copyright © 2018年 nearwmy. All rights reserved.
//

#import "DCUIViewControllerHUD.h"
#import "NSBundle+TZImagePicker.h"
#import "UIView+Layout.h"

@implementation DCUIViewControllerHUD 

- (void)showProgressHUD{
    
    if (!self.progressHUD) {
        self.progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.progressHUD setBackgroundColor:[UIColor clearColor]];
        
        self.HUDContainer = [[UIView alloc] init];
        self.HUDContainer.layer.cornerRadius = 8;
        self.HUDContainer.clipsToBounds = YES;
        self.HUDContainer.backgroundColor = [UIColor darkGrayColor];
        self.HUDContainer.alpha = 0.7;
        
        self.HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        self.HUDLabel = [[UILabel alloc] init];
        self.HUDLabel.textAlignment = NSTextAlignmentCenter;
        self.HUDLabel.text = [NSBundle tz_localizedStringForKey:@"Processing..."];;
        self.HUDLabel.font = [UIFont systemFontOfSize:15];
        self.HUDLabel.textColor = [UIColor whiteColor];
        
        [self.HUDContainer addSubview:self.HUDLabel];
        [self.HUDContainer addSubview:self.HUDIndicatorView];
        [self.progressHUD addSubview:self.HUDContainer];
        
        self.HUDContainer.frame = CGRectMake((self.view.tz_width - 120) / 2, (self.view.tz_height - 90) / 2, 120, 90);
        self.HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        self.HUDLabel.frame = CGRectMake(0,40, 120, 50);
    }
    [self.HUDIndicatorView startAnimating];    
    [[UIApplication sharedApplication].keyWindow addSubview:self.progressHUD];
    
    // if over time, dismiss HUD automatic
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf hideProgressHUD];
    });
}

- (void)hideProgressHUD{
    if (self.progressHUD) {
        [self.HUDIndicatorView stopAnimating];
        [self.progressHUD removeFromSuperview];
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.HUDContainer.frame = CGRectMake((self.view.tz_width - 120) / 2, (self.view.tz_height - 90) / 2, 120, 90);
    self.HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
    self.HUDLabel.frame = CGRectMake(0,40, 120, 50);
}

@end
