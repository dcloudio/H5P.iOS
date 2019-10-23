//
//  QUCSuggestTextFieldView.h
//  qucsdkFramework
//
//  Created by simaopig on 14-7-3.
//  Copyright (c) 2014年 Qihoo.360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QUCTextField.h"
@class QUCSuggestTextFieldDataSource;
@class QUCSuggestTextFieldView;

@protocol QUCSuggestTextFieldDataSource <NSObject>
@required
//get suggest array
-(NSArray *)possibleQucSuggestDataForString:(NSString *)string IgnoreCase:(BOOL)ignoreCase;

@optional
//suggestion数据已经生成回调
-(void)suggestSelected:(QUCSuggestTextFieldView *)textFieldView;
@end

@interface QUCSuggestTextFieldView : QUCTextField<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,assign) BOOL      ignoreCase;//是否忽略大小写
@property (nonatomic,strong) UIColor   *suggestTableBackgroundColor;//Table背景色
@property (nonatomic,strong) UIColor   *suggestTableCellTextColor;//Table每行label的背景色
@property (nonatomic,strong) UIFont    *suggestTableCellTextFont;//Table每行Label的字体
@property (nonatomic,assign) NSInteger suggestTableShowCellNum;//显示多少行
@property (nonatomic,assign) CGFloat   suggestTableCellHeight;//每行行高
@property (nonatomic,weak) id<QUCSuggestTextFieldDataSource> dataSource;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textFieldDidChangeWithNotification:(NSNotification *)notify;
- (void)closeSuggestionTableView;
@end
