//
//  PDRCoreAppResource.h
//  libPDRCore
//
//  Created by DCloud on 2018/6/20.
//  Copyright © 2018年 DCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDRCoreAppInfo.h"

typedef enum{
    PDRCoreAppResourceStatusNotLoad = 1,
    PDRCoreAppResourceStatusLoading,
    PDRCoreAppResourceStatusLoaded
} PDRCoreAppResourceStatus;

typedef enum{
    PDRCoreAppResourceKindPlusApiJs = (1 << 0),
    PDRCoreAppResourceKindUniappViewJs = (1 << 1),
    PDRCoreAppResourceKindUniappServiceJs = (1 << 2),
} PDRCoreAppResourceKind;

@class PDRCoreAppResourceLoader;
@protocol  PDRCoreAppResourceLoaderProtocol <NSObject>
- (void)resourceLoader:(PDRCoreAppResourceLoader*)loader complete:(id)result;
@end

typedef void(^CompelteResult)(id result);
@interface PDRCoreAppResourceLoader : NSObject
@property(nonatomic, assign)PDRCoreAppResourceStatus loadStatus;
@property(nonatomic, retain)id res;
@property(nonatomic, retain)id userdata;
@property(nonatomic, assign)PDRCoreAppResourceKind kind;
- (void)loadResourceWithHandle:(void(^)(CompelteResult result))Handle withDelegate:(id<PDRCoreAppResourceLoaderProtocol>)delegate;
- (void)removeResourceDelegate:(id)delegate;
- (void)removeAllResourceDelegate;
@end

@interface PDRCoreAppResource : NSObject
@property(nonatomic,copy)NSString * universion;
@property(nonatomic,copy)NSString * appRootPath;
@property(nonatomic,assign)H5CoreUniappControlMode controlMode;
@property(nonatomic, assign)H5CoreUniappControlRenderer renderer;
+(PDRCoreAppResource*)sharedInstance;
+ (NSString*)uniAppPathDebug;
- (void)clearAllDelegate;
+ (PDRCoreAppResourceLoader*)getJsFramewrokWithKind:(PDRCoreAppResourceKind)kind;
+ (PDRCoreAppResourceLoader*)getJsFramewrokWithKind:(PDRCoreAppResourceKind)kind withDelegate:(id<PDRCoreAppResourceLoaderProtocol>)delegate;
+ (PDRCoreAppResourceLoader*)loadJsFramewrokWithKind:(PDRCoreAppResourceKind)kind withDelegate:(id<PDRCoreAppResourceLoaderProtocol>)delegate;
+ (void)removeJsFramewrokDelegate:(id<PDRCoreAppResourceLoaderProtocol>)delegate forKind:(PDRCoreAppResourceKind)kind;
+ (void)clearJsFramewrokWithKind:(PDRCoreAppResourceKind)kind;
@end

#define PDRCoreAppResourceLoaderGet(kind) ([PDRCoreAppResource getJsFramewrokWithKind:kind])
#define PDRCoreAppResourceGet(kind) PDRCoreAppResourceLoaderGet(kind).res
