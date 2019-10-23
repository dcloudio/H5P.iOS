/**
 * Created by G-Canvas Open Source Team.
 * Copyright (c) 2017, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information, please view
 * the LICENSE file in the root directory of this source tree.
 */

#import "GCanvasPlugin.h"
#import "GCVCommon.h"
#import "GCVFont.h"
#import "GCVLog.h"

#include "GCanvas.hpp"
#include "GCanvasManager.h"
#include "Log.h"
#import "PGPlugin.h"
#import "PTPathUtil.h"

@interface GCanvasPlugin()

@property(nonatomic, strong) NSString *componentId;
@property(nonatomic, assign) GCanvas *gcanvas;
@property(nonatomic, strong) NSMutableArray *renderCommandArray;
@property(nonatomic, strong) NSMutableDictionary *textureDict;

@property(nonatomic, weak) GLKView *glkview;

@end

@implementation GCanvasPlugin

+ (void)setLogLevel:(NSUInteger)logLevel{
    if( logLevel < LOG_LEVEL_DEBUG || logLevel > LOG_LEVEL_FATAL ) return;
#ifdef DEBUG
    [GCVLog sharedInstance].logLevel = (GCVLogLevel)logLevel;
#endif
    SetLogLevel((LogLevel)logLevel);
}

+ (FetchPluginBlock)GetFetchPluginBlock{
    static FetchPluginBlock gFetchPluginBlock;
    return gFetchPluginBlock;
}

+ (void)setFetchPlugin:(FetchPluginBlock)block
{
    FetchPluginBlock fetchPluginBlock = [self GetFetchPluginBlock];
    fetchPluginBlock = block;
}


- (instancetype)initWithComponentId:(NSString*)componentId{
    self = [super init];
    if (self){
        self.renderCommandArray = [[NSMutableArray alloc] init];
        self.textureDict = NSMutableDictionary.dictionary;
        
        self.gcanvasInited = NO;
        self.componentId = componentId;
        
        gcanvas::GCanvasManager* manager = gcanvas::GCanvasManager::GetManager();
        std::string key = [componentId UTF8String];

        manager->NewCanvas(key);
        self.gcanvas = manager->GetCanvas(key);
        
    #ifdef DEBUG
        SetLogLevel(LOG_LEVEL_DEBUG);
    #else
        SetLogLevel(LOG_LEVEL_INFO);
    #endif
    }
    return self;
}

- (void)dealloc{
    [self removeGCanvas];
}

- (void)setFrame:(CGRect)frame{
    if( !self.gcanvas ) return;
    if( !self.gcanvasInited ){
    self.gcanvas->OnSurfaceChanged(0, 0, frame.size.width, frame.size.height);
    self.gcanvasInited = YES;
    }
}

- (void)setClearColor:(UIColor*)color{
    if( !self.gcanvas ) return;
    
    if( color ){
        CGFloat r, g, b, a;
        BOOL ret = [color getRed:&r green:&g blue:&b alpha:&a];
        if( ret ){
            GColorRGBA c;
            c.rgba.r = r;
            c.rgba.g = g;
            c.rgba.b = b;
            c.rgba.a = a;
            self.gcanvas->SetClearColor(c);
        }
    }
}

- (void)addCommands:(NSString*)commands{
    if (commands){
        @synchronized (self) {
            [self.renderCommandArray addObject:commands];
        }
    }
}

- (void)removeCommands{
    @synchronized (self) {
        [self.renderCommandArray removeAllObjects];
    }
}

- (void)execCommands{
    if( !self.gcanvas || !self.gcanvasInited ) return;
    
    @synchronized (self) {
        if(self.renderCommandArray.count == 0){
            return;
        }
        //NSString* cmd = self.renderCommandArray[0];
        NSString* cmd = [self.renderCommandArray componentsJoinedByString:@""];
        int cmdLen = (int)strlen(cmd.UTF8String);
        GCVLOG_METHOD(@"execCommands, len:%d, command=%@", cmdLen, cmd);
        self.gcanvas->Render(cmd.UTF8String, cmdLen);
        [self.renderCommandArray removeAllObjects];
        //[self.renderCommandArray removeObjectAtIndex:0];
    }
}

- (void)releaseManager{
    gcanvas::GCanvasManager::Release();
}

- (void)removeGCanvas{
    gcanvas::GCanvasManager* manager = gcanvas::GCanvasManager::GetManager();
    manager->RemoveCanvas([self.componentId UTF8String]);
    
//    if( manager->canvasCount() <= 0 ){
//        [[GCVFont sharedInstance] cleanFont];
//    }
    
    @synchronized(self){
        [self.textureDict enumerateKeysAndObjectsUsingBlock:^(id  key, id value, BOOL * _Nonnull stop) {
            GLuint tid = (GLuint)[value integerValue];
            if(tid > 0){
                glDeleteTextures(1, &tid);
            }
        }];
        [self.textureDict removeAllObjects];
        self.textureDict = nil;
    }
    
    self.gcanvas = nil;
}

- (GLuint)getTextureId:(NSUInteger)aid{
    if( !self.gcanvas ) return 0;
    
    @synchronized(self){
        GLuint tid = (GLuint)([self.textureDict[@(aid)] integerValue]);
        return tid;
    }
}

- (void)addTextureId:(NSUInteger)tid withAppId:(NSUInteger)aid width:(NSUInteger)width height:(NSUInteger)height offscreen:(BOOL)offscreen{
    if( !self.gcanvas ) return;
    
    self.gcanvas->AddTexture((int)aid, (int)tid, (int)width, (int)height);
    if( offscreen ){
        self.gcanvas->AddOfflineTexture((int)aid, (int)tid);
    }
    @synchronized(self){
        self.textureDict[@(aid)] = @(tid);
    }
}

- (void)addTextureId:(NSUInteger)tid withAppId:(NSUInteger)aid width:(NSUInteger)width height:(NSUInteger)height{
    [self addTextureId:tid withAppId:aid width:width height:height offscreen:NO];
}

- (void)setImageLoader:(id<GCVImageLoaderProtocol>)loader{
    [GCVCommon sharedInstance].imageLoader = loader;
}

- (void)setDevicePixelRatio:(double)ratio{
    if( !self.gcanvas ) return;

    self.gcanvas->SetDevicePixelRatio(ratio);
}

- (void)setContextType:(GCVContextType)contextType{
    if( !self.gcanvas ) return;
    
    self.gcanvas->mContextType = (GCVContextTypeWebGL == contextType ) ? GCVContextTypeWebGL : GCVContextType2D;
    
    //register function for GFont and WebGL texImage2D && texSubImage2D.
    if( self.gcanvas->mContextType != 0 ){
        self.gcanvas->SetGWebGLTxtImage2DFunc(iOS_GCanvas_GWebGLTxtImage2D);
        self.gcanvas->SetGWebGLTxtSubImage2DFunc(iOS_GCanvas_GWebGLTxtSubImage2D);
        self.gcanvas->SetGWebGLBindToGLKViewFunc(iOS_GCanvas_Bind_To_GLKView);
    } else {
//        self.gcanvas->SetG2DFontDrawTextFunc(iOS_GCanvas_Draw_Text);
    }
}

- (int)contextType{
    if( !self.gcanvas ) return 0;
    return self.gcanvas->mContextType;
}

- (CGFloat)fps{
    if( !self.gcanvas ) return 0;
    return self.gcanvas->mFps;
}

- (GLuint)textureId{
    if( !self.gcanvas ) return 0;
    return self.gcanvas->GetFboTexture()->GetTextureID();
}

- (NSString*)getSyncResult{
    if( !self.gcanvas ) return @"";

   if( !self.gcanvas->mResult.empty() ){
        NSString *retResult = [[NSString alloc] initWithUTF8String:self.gcanvas->mResult.c_str()];
        self.gcanvas->setSyncResult("");
        return retResult;
    }
    return @"";
}

- (void)setGLKView:(GLKView*)glkview{
    self.glkview = glkview;
}

- (GLKView*)getGLKView{
    return self.glkview;
}



#pragma mark - iOS implementation of Font & texImage
/**
 * Draw GCanvas2D Text with GCVFont.
 *
 * @param text          text string to draw
 * @param text_length   text length
 * @param x             draw position x
 * @param y             draw position y
 * @param isStroke      isStroke flag
 * @param context       see GCanvasContext
 *
 */
void iOS_GCanvas_Draw_Text(const unsigned short *text, unsigned int text_length, float x, float y, bool isStroke, GCanvasContext *context, void* fontContext){
    //    LOG_D("[iOS_GCanvas_Draw_Text] text[%d]=%s, point=(%.2f, %.2f)", text_length, text, x, y);
    if (text == nullptr || text_length == 0) {
        return;
    }
    
    GCanvasState *current_state_ = context->GetCurrentState();
    GCVFont *curFont = (__bridge GCVFont*)fontContext;
    
    [curFont resetWithFontStyle:current_state_->mFont isStroke:isStroke context:context];
    NSString *string = [[NSString alloc] initWithBytes:text length:text_length encoding:NSUTF8StringEncoding];
    GFontLayout *fontLayout = [curFont getLayoutForString:string withFontStyle:[NSString stringWithUTF8String:current_state_->mFont->GetName().c_str()]];
    CGPoint destPoint = [curFont adjustTextPenPoint:CGPointMake(x, y)
                                          textAlign:current_state_->mTextAlign
                                           baseLine:current_state_->mTextBaseline
                                            metrics:fontLayout.metrics];
    
    current_state_->mShader->SetOverideTextureColor(1);
    
    glActiveTexture(GL_TEXTURE0);
    
    [curFont drawString:string withFontStyle:[NSString stringWithUTF8String:current_state_->mFont->GetName().c_str()] withLayout:fontLayout withPosition:destPoint];
    
    
}

float iOS_GCanvas_Mesure_Text(const char *text, unsigned int text_length, GCanvasContext *context, void* fontContext){
    if (text == nullptr || text_length == 0) {
        return 0;
    }
    
    GCanvasState *current_state_ = context->GetCurrentState();
    GCVFont *curFont = (__bridge GCVFont*)fontContext;
    
    [curFont resetWithFontStyle:current_state_->mFont isStroke:false context:context];
    NSString *string = [[NSString alloc] initWithBytes:text length:text_length encoding:NSUTF8StringEncoding];
    GFontLayout *fontLayout = [curFont getLayoutForString:string withFontStyle:[NSString stringWithUTF8String:current_state_->mFont->GetName().c_str()]];
    
    return fontLayout.metrics.width;
}

/**
 * Fetch GCVImageCache by image source, create texImage2D with imageData.
 * create textImage2D success, while imageCache loaded.
 *
 * @param target            texutre target to render
 * @param level             level
 * @param internalformat    internalformat
 * @param format            format
 * @param type              type
 * @param src               image src to loader
 *
 */
void iOS_GCanvas_GWebGLTxtImage2D(GLenum target, GLint level, GLenum internalformat,
                                  GLenum format, GLenum type,  const char *src){
    NSString *imageStr = [[NSString alloc] initWithUTF8String:src];
    GCVImageCache *imageCache = [[GCVCommon sharedInstance] fetchLoadImage:imageStr];
    
    void (^glTexImage2DBlock)(GCVImageCache*) = ^(GCVImageCache* cache){
        LOG_D("width=%f, height=%f, image=%p", imageCache.width, imageCache.height, imageCache.image);
        
        GLint width = imageCache.width;
        GLint height = imageCache.height;
        
        CGRect rect = CGRectMake(0, 0, width, height);
        CGBitmapInfo info =  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        NSMutableData *pixelData = [NSMutableData dataWithLength:width*height*4];
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixelData.mutableBytes, width, height, 8, 4 * width, colorSpace, info);
        CGColorSpaceRelease(colorSpace);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, imageCache.image.CGImage);
        CGContextRelease(context);
        
        glTexImage2D(target, level, internalformat, width, height, 0, format, type, pixelData.bytes);
    };
    
    if( imageCache ) {
        glTexImage2DBlock(imageCache);
    } else {
        [[GCVCommon sharedInstance] addPreLoadImage:imageStr completion:^(GCVImageCache *imageCache, BOOL fromCache){
            if( imageCache ){
                glTexImage2DBlock(imageCache);
            }
        }];
    }
}

/**
 * Fetch GCVImageCache by image source, create texImage2D with imageData.
 * create textImage2D success, while imageCache loaded.
 *
 * @param target            texutre target to render
 * @param level             level
 * @param xoffset           xoffset
 * @param yoffset           yoffset
 * @param format            format
 * @param type              type
 * @param src               image src to loader
 *
 */
void iOS_GCanvas_GWebGLTxtSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
                                     GLenum format, GLenum type,  const char *src){
    NSString *imageStr = [[NSString alloc] initWithUTF8String:src];
    GCVImageCache *imageCache = [[GCVCommon sharedInstance] fetchLoadImage:imageStr];
    
    void (^glTexSubImage2DBlock)(GCVImageCache*) = ^(GCVImageCache* cache){
        LOG_D("width=%f, height=%f, image=%p", imageCache.width, imageCache.height, imageCache.image);
        
        GLint width = imageCache.width;
        GLint height = imageCache.height;
        
        CGRect rect = CGRectMake(0, 0, width, height);
        CGBitmapInfo info =  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
        NSMutableData *pixelData = [NSMutableData dataWithLength:width*height*4];

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixelData.mutableBytes, width, height, 8, 4 * width, colorSpace, info);
        CGColorSpaceRelease(colorSpace);
        CGContextClearRect(context, rect);
        CGContextDrawImage(context, rect, imageCache.image.CGImage);
        CGContextRelease(context);
        
        glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixelData.bytes);
    };

    if( imageCache ){
        glTexSubImage2DBlock(imageCache);
    } else {
        [[GCVCommon sharedInstance] addPreLoadImage:imageStr completion:^(GCVImageCache *imageCache, BOOL fromCache){
            if( imageCache ){
                glTexSubImage2DBlock(imageCache);
            }
        }];
    }
}

void iOS_GCanvas_Bind_To_GLKView(std::string contextId){
    if( [GCanvasPlugin GetFetchPluginBlock] ){
        FetchPluginBlock block = [GCanvasPlugin GetFetchPluginBlock];
        GCanvasPlugin *plugin = block([NSString stringWithUTF8String:contextId.c_str()]);
        GLKView *glkview = [plugin getGLKView];
        [glkview bindDrawable];
    }
}

#pragma mark - dcloud
- (float)measureText:(NSString*)text fontStyle:(NSString*)fontStyle {
    if( !self.gcanvas || !self.gcanvasInited ) return -1;
    return self.gcanvas->execMeasureTextWidthWithFont([text UTF8String], fontStyle.UTF8String);
}

- (void)getData:(NSArray*)data toTempFilePath:(NSString*)parentPath callback:(GCanvasPluginCallback)callback {
    if( !self.gcanvas || !self.gcanvasInited ) {
        callback(@{@"errMsg":@"Canvas not ready"});
        return;
    }
    short maxW = self.gcanvas->GetWidth();
    short maxH = self.gcanvas->GetHeight();
    CGFloat x = [PGPluginParamHelper getFloatValue:[data objectAtIndex:0] defalut:0];
    CGFloat y = [PGPluginParamHelper getFloatValue:[data objectAtIndex:1] defalut:0];
    x = MAX(MIN(x, maxW), 0);
    y = MAX(MIN(y, maxH), 0);
    CGFloat w = [PGPluginParamHelper getFloatValue:[data objectAtIndex:2] defalut:maxW-x];
    CGFloat h = [PGPluginParamHelper getFloatValue:[data objectAtIndex:3] defalut:maxH-y];
    w = MIN(w, maxW);
    h = MIN(h, maxH);
    CGFloat dw = [PGPluginParamHelper getFloatValue:[data objectAtIndex:4] defalut:w];
    CGFloat dh = [PGPluginParamHelper getFloatValue:[data objectAtIndex:5] defalut:h];
    
    CGRect rect = CGRectMake(x, y, w, h);
    if ( CGRectIsEmpty(rect) || CGRectIsNull(rect) ) {
        callback(@{@"errMsg":@"Invaild paramer"});
        return;
    }
    NSString *fileType = [PGPluginParamHelper getStringValue:[data objectAtIndex:6] defalut:nil];
    int quality = [PGPluginParamHelper getIntValue:[data objectAtIndex:7] defalut:1];
    quality = MAX(MIN(1, quality),0);
    
    self.gcanvas->BindFBO();
    std::string pixelsData;
    self.gcanvas->GetImageData(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, false, pixelsData);
    self.gcanvas->UnbindFBO();
    CGSize imageSize = CGSizeMake(dw, dh);
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, (unsigned char *)pixelsData.c_str(), pixelsData.length(), NULL);
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * rect.size.width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(rect.size.width, rect.size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    CGDataProviderRelease(provider);
    
    
    if ( !CGSizeEqualToSize(rect.size, imageSize) ) {
        CGContextRef imageContext = CGBitmapContextCreate(NULL, (size_t)imageSize.width, (size_t)imageSize.height, 8, (size_t)imageSize.width * 4, colorSpaceRef,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, imageSize.width, imageSize.height), imageRef);
        CGImageRelease(imageRef);
        imageRef = CGBitmapContextCreateImage(imageContext);
        CGContextRelease(imageContext);
    }
    CGColorSpaceRelease(colorSpaceRef);
    
    @autoreleasepool {
        UIImage *myImage = [UIImage imageWithCGImage:imageRef];
        NSData *data = nil;
        NSString *ext = @"jpg";
        if ( fileType && [fileType isEqualToString:@"png"] ) {
            data = UIImagePNGRepresentation(myImage);
            ext = @"png";
        } else {
            data = UIImageJPEGRepresentation(myImage, quality);
        }
        
        NSString *imageName = [parentPath stringByAppendingPathComponent:[PTPathUtil uniqueFileName:ext]];
        [data writeToFile:imageName atomically:YES];
        imageName = [PTPathUtil wrapFileScheme:imageName];
        callback(@{@"errMsg":@"canvasToTempFilePath:ok",@"tempFilePath":imageName?:@""});
    }
}

- (void)getImageData:(NSArray*)data callback:(GCanvasPluginCallback)callback  {
    if( !self.gcanvas || !self.gcanvasInited ) return;
    
    short maxW = self.gcanvas->GetWidth();
    short maxH = self.gcanvas->GetHeight();
    CGFloat x = [PGPluginParamHelper getFloatValue:[data objectAtIndex:0] defalut:0];
    CGFloat y = [PGPluginParamHelper getFloatValue:[data objectAtIndex:1] defalut:0];
    x = MAX(MIN(x, maxW), 0);
    y = MAX(MIN(y, maxH), 0);
    CGFloat w = [PGPluginParamHelper getFloatValue:[data objectAtIndex:2] defalut:maxW-x];
    CGFloat h = [PGPluginParamHelper getFloatValue:[data objectAtIndex:3] defalut:maxH-y];
    w = MIN(w, maxW);
    h = MIN(h, maxH);

    self.gcanvas->BindFBO();
    std::string pixelsData;
    self.gcanvas->GetImageData(x, y, w, h, true, pixelsData);
    self.gcanvas->UnbindFBO();
    NSString *stre = [NSString stringWithCString:pixelsData.c_str() encoding:NSUTF8StringEncoding];
    callback(@{@"data":stre?:@"", @"width":@(w), @"height":@(h)});
}

- (void)putImageData:(NSString*)strData toRect:(CGRect)rect {
}

@end
