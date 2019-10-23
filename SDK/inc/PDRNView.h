//
//  PDRNView.h
//  Pandora
//
//  Created by Pro_C Mac on 13-4-7.
//
//

#import "PGMethod.h"
#import "PGPlugin.h"
#import <UIKit/UIKit.h>

typedef enum PDRNViewBelongTo {
    PDRNViewUnmarried,
    PDRNViewThrowout,
    PDRNViewInWindow,
    PDRNViewInWebview,
    PDRNViewInWebviewGroup,
    PDRNViewInTab,
}PDRNViewBelongTo;

typedef NS_OPTIONS(NSUInteger, PDRNViewFeatureMask) {
    PDRNViewFeatureMaskAsFllowView = (1 << 0),
    PDRNViewFeatureMaskCreateFromWebviewStyleSubNviews = (1 << 1),
    PDRNViewFeatureMaskStart = 2
};

/**
 NView基类所有扩展出的NView插件都应该从该类继承
 */
@interface PDRNView : UIView
/// @brief JavaScript执行环境
@property (nonatomic, assign)PGPlugin *JSContext;
/// @brief NView插件类别名称
@property (nonatomic, copy) NSString *identity;
@property (nonatomic, assign)BOOL preventLayout;
@property (nonatomic, readonly)UIView *statusbarView;
/// @brief NView唯一标识
@property (nonatomic, copy) NSString *viewName;
@property (nonatomic, copy) NSString *viewUUID;
@property (nonatomic, copy) NSString *jsCallbackId;
@property (nonatomic, copy) NSString *parent;
@property (nonatomic, strong)UIViewController*  viewController;
@property (nonatomic, retain, readonly)NSDictionary* options;

@property (nonatomic, assign)BOOL autoAppendStatusBar;

@property(nonatomic, assign)PDRNViewBelongTo belongTo;
@property(nonatomic, assign)NSUInteger featureMask;
/**
 @brief 使用JS NViewOption创建NView 子类应该重写该方法实现初始化
 @param options NViewOption
 @return id NView对象
 */
- (id)initWithOptions:(NSDictionary*)options;
- (id)initWithOptions:(NSDictionary*)aOptios withJsContext:(PGPlugin*)jsContext;
- (id)initWithFrame:(CGRect)frame withOptions:(NSDictionary*)aOptios withJsContext:(PGPlugin*)jsContext;
- (void)setOptions:(NSDictionary *)options;
- (void)createStatusbar;
- (void)destoryStatusbar;
- (void)setStatusbarColor:(UIColor*)bkColor;
/**
 @brief 分发event事件
 @param evtName 事件名称
 @return 无
 */
- (void)dispatchEvent:(NSString*)evtName;
/**
 @brief NView从NWindow上移除时回调
 @param
 @return 无
 */
- (void)onRemoveFormSuperView;
- (void)onLayout_;
- (NSData*)getMettics:( PGMethod*) pMethod;
// 返回当前控件最小尺寸，可以是%，或者PX值，或者Auto
- (NSDictionary*)GetMiniControllerSize:(int)nOri;
- (void)CreateView:(PGMethod*)pMethod;
- (NSString*)getObjectString;
- (void)removeFormUIStrack;
- (void)removeStyleForKey:(NSString*)key;
- (void)setStyle:(id)value forKey:(NSString*)key;
-(CGRect)measureSubViewRect:(CGRect)wBounds;
- (void)addFeatureMask:(PDRNViewFeatureMask)mask;
- (BOOL)hasFeatureMask:(PDRNViewFeatureMask)mask;
- (CGFloat)getStatusBarHeight;
- (BOOL)hasStatusBar;
+ (BOOL)isViewVisual:(UIView*)view;

@end

