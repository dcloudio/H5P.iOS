//
//  PDRCore.h
//  Pandora
//
//  Created by Mac Pro on 12-12-22.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDRCoreApp.h"
#import "PGMethod.h"

@class PDRCoreAppFrame;

@interface PDRAppFeatureItem : NSObject {
    NSMutableDictionary *_extends;
}
@property(nonatomic, assign)BOOL global;
@property(nonatomic, retain)NSString *classname;
@property(nonatomic, retain)NSString *baseClassname;
@property(nonatomic, assign)BOOL autoStart;
@property(nonatomic, retain)NSString *argument;
@property(nonatomic, retain)NSString *serverIdentifier;
@property(nonatomic, retain)NSString *serverImpClassName;
@property(nonatomic, retain)NSDictionary *extends;
@property(nonatomic, assign)BOOL  supportSimulator;
- (void)addExtendFromDictionary:(NSDictionary*)dict;
@end

@interface PDRAppFeatureList : NSObject {
    NSMutableDictionary *_featureList;
    NSMutableDictionary *_servers;
    NSMutableDictionary *_runServers;
}
- (void)load;
- (void)combineCustomFeature;
- (void)registCustromFeature:(PDRExendPluginInfo*)info;
- (void)runServers;
- (NSArray*)autoStartPlugins;
- (NSString*)getClassName:(NSString*)pluginName;
- (PDRAppFeatureItem*)getPuginInfo:(NSString*)pluginName;
- (NSDictionary*)getPuginExtend:(NSString*)pluginName;
- (NSDictionary*)getServers;
- (id)getServerByIdentifier:(NSString*)identifier;
@end

typedef NS_ENUM(NSInteger, H5CommandQueueStatus) {
    H5CommandQueueStatusIdle = 0,
    H5CommandQueueStatusExec,
    H5CommandQueueStatusPause,
    H5CommandQueueStatusStop
};

@protocol PDRCoreJSObjects <NSObject>
@required
- (id) getCommandInstance:(NSString*)pluginName
                   HtmlID:(NSString*)pHtmlID
               appContext:(PDRCoreApp*)JSAppContext
             frameContext:(PDRCoreAppFrame*)JSFrameContext;
- (PGPlugin*)getPluginObjFromName:(NSString*)name;
- (PGPlugin*)getPluginObjFromName:(NSString*)pluginName inWebviewId:(NSString*)webviewId;
@optional
- (void)handleAppUpgradesNoClose;
- (void)handleNeedLayout;
- (void)handleAppFrameWillClose:(PDRCoreAppFrame*)appFrame;
- (void)handleAppClose;
@end

@interface PDRCoreGlobalJSObjects : NSObject<PDRCoreJSObjects>{
    NSMutableDictionary* m_pWebViewPluginMap;
}
@end

@interface PDRCoreFrameJSObjects : NSObject<PDRCoreJSObjects>{
    NSMutableDictionary* m_pWebViewPluginMap;
}
@end

@interface PDRCoreFeature : NSObject {
    PDRCoreGlobalJSObjects *_globalJSObjects;
    PDRCoreFrameJSObjects *_frameJSObjects;
    
    NSMutableArray* _queue;
    UIAlertView *_userAuthAlertView;
}
@property(nonatomic, retain)PGMethod *currentUserAuthMethod;
@property(nonatomic, retain)PGPlugin *currentUserAuthObj;
@property(nonatomic, assign)H5CommandQueueStatus queueStatus;
@property (nonatomic, readonly) BOOL currentlyExecuting;
@property(nonatomic, assign) PDRCoreAppFrame* JSFrameContext;//js运行frame
@property(nonatomic, assign) PDRCoreApp* JSAppContext; //js运行所属的APP
- (id)Execute:(PGMethod*) pPadoraMethod;
- (void)executeJsCmdWithString:(NSString*)pJsonString;
- (void)executeJsCmdWithPGMethod:(PGMethod*)pMethod;
- (void)appendJSMethodToExecQueuesAndExec:(NSString*)pJsonString;
- (void)createAutoStartPlugins;
- (PGPlugin*)getPluginObjFromName:(NSString*)name;
- (PGPlugin*)getPluginObjFromName:(NSString*)name inWebviewId:(NSString*)webviewId;
- (PGPlugin*)createPlugin:(NSString*)name inWebviewId:(NSString*)webviewId;
- (PGPlugin*)getAndCreateGlobalPlugin:(NSString *)name;
- (void)handleAppUpgradesNoClose;
- (void)handleNeedLayout;
- (void)handleAppFrameWillClose:(PDRCoreAppFrame*)appFrame;
- (void)handleAppFrameDidShow:(PDRCoreAppFrame*)appFrame;
- (void)handleAppFrameDidHidden:(PDRCoreAppFrame*)appFrame;
- (void)handleAppClose;
- (id)handleSysEvent:(PDRCoreSysEvent)evt withObject:(id)object;
@end

//@interface PDRCoreAppFrameFeature : PDRCoreFeature
//@end
//
//@interface PDRCoreAppFeature : PDRCoreFeature
//- (void)createAutoStartPlugins;
//- (void)handleAppClose;
//- (void)handleAppFrameWillClose:(PDRCoreAppFrame*)appFrame;
//@end


