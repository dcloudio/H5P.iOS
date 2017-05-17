//
//  PGZip.m
//  Pandora
//
//  Created by Pro_C Mac on 13-2-26.
//
//

#import "PGZip.h"
#import "PDRCoreWindowManager.h"
#import "PDRCoreAppFrame.h"
#import "ZipArchive.h"
#import "PTPathUtil.h"
#import "PDRCommonString.h"
#import "PDRToolSystemEx.h"

typedef enum {
    PGZCompressImgOutputFormatJPG,
    PGZCompressImgOutputFormatPNG
}PGZCompressImgOutputFormat;

@interface PGZCompressImgOptions : NSObject {
    id _width;
    id _height;
    id _clip;
}
@property(nonatomic, retain)NSString *inputPath;
@property(nonatomic, retain)NSString *outputPath;
@property(nonatomic, assign)BOOL isOverwrite;
@property(nonatomic, assign)CGRect clipRect;
@property(nonatomic, assign)BOOL isClipValid;
@property(nonatomic, assign)CGSize outputSize;
@property(nonatomic, assign)CGFloat outputQuality;
@property(nonatomic, assign)PGZCompressImgOutputFormat outputFormat;
@property(nonatomic, assign)int transform;
+(PGZCompressImgOptions*)parse:(NSDictionary*)dict
                   withContext:(PDRCoreApp*)context withBaseUrl:(NSString*)baseUrl ;
- (void)parseScaleSize:(CGSize)inputImgSize;
- (void)parseClipSize:(CGSize)inputImgSize;
@end

@implementation PGZip

- (void)compress:(PGMethod*)commands
{
    int zipState = PGPluginOK;
    NSString* pSrcPath = [commands.arguments objectAtIndex:0];
    NSString* pZipFile = [commands.arguments objectAtIndex:1];
    NSString* pCallBackId = [commands.arguments objectAtIndex:2];

    pSrcPath = [PTPathUtil absolutePath:pSrcPath withContext:self.appContext];
    pZipFile = [PTPathUtil absolutePath:pZipFile withContext:self.appContext];
    
    BOOL bDir = FALSE;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ( ![fileManager fileExistsAtPath:pSrcPath isDirectory:&bDir] ) {
        zipState = PGPluginErrorFileNotFound;
        goto Error;
    }
    
    if ( ![PTPathUtil allowsWritePath:pZipFile withContext:self.appContext] ) {
        zipState = PGPluginErrorNotAllowWrite;
        goto Error;
    }
    
    if ( [fileManager fileExistsAtPath:pZipFile isDirectory:&bDir] ) {
        zipState = PGPluginErrorFileExist;
        goto Error;
    }
    
    [PTPathUtil ensureDirExist:[pZipFile stringByDeletingLastPathComponent]];
    
    ZipArchive* pZipa = [[ZipArchive alloc] init];
    if ( pZipa ) {
        if ( [pZipa CreateZipFile2:pZipFile] ) {
            if ( bDir ) {
                // 首先每局指定目录下的文件
                
                NSDirectoryEnumerator *dirEnum;
                NSFileManager *fileManager = [NSFileManager defaultManager];
                dirEnum = [fileManager enumeratorAtPath:pSrcPath];
                NSString *path = nil;
                while ( (path = [dirEnum nextObject]) != nil )  {
                    BOOL isDir = FALSE;
                    NSString *destPath = [pSrcPath stringByAppendingPathComponent:path];
                    [fileManager fileExistsAtPath:destPath isDirectory:&isDir];
                    if ( !isDir ) {
                        BOOL bRet = [pZipa addFileToZip:destPath newname:path];
                        if (bRet == NO) {
                            zipState = PGPluginErrorZipFail;
                            break;
                        }
                    } else {
                        NSArray* pPathArray = [fileManager contentsOfDirectoryAtPath:destPath error:nil];
                        if ( 0 == [pPathArray count] ) {
                            BOOL bRet = [pZipa addFileToZip:destPath newname:[NSString stringWithFormat:@"%@/", path]];
                            if (bRet == NO) {
                                zipState = PGPluginErrorZipFail;
                                break;
                            }
                        }
                    }
                }
            } else {
                BOOL bRet = [pZipa addFileToZip:pSrcPath newname:[pSrcPath lastPathComponent]];
                if (bRet == NO) {
                    zipState = PGPluginErrorZipFail;
                }
            }
            [pZipa CloseZipFile2];
        } else {
            zipState = PGPluginErrorFileCreateFail;
        }
        [pZipa release];
    }
Error :
    if ( PGPluginOK != zipState ) {
        PDRPluginResult *result = nil;
        result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                              messageToErrorObject:zipState
                                       withMessage:[self errorMsgWithCode:zipState]];
        [self toCallback:pCallBackId withReslut:[result toJSONString]];
    } else {
        // 成功了 回调
        PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK];
        [self toCallback:pCallBackId withReslut:[result toJSONString]];
    }
}

- (void)decompress:(PGMethod*)commands
{    
    if ( commands ) {
        __block int zipState = PGPluginErrorUnZipFail;
        NSString* pZipFile = [commands.arguments objectAtIndex:0];
        NSString* pFileDic = [commands.arguments objectAtIndex:1];
        NSString* pCallBackId = [commands.arguments objectAtIndex:2];        
        
        pZipFile = [PTPathUtil absolutePath:pZipFile withContext:self.appContext];
        pFileDic = [PTPathUtil absolutePath:pFileDic withContext:self.appContext];
        
        if ( ![PTPathUtil allowsWritePath:pFileDic withContext:self.appContext] ) {
            zipState = PGPluginErrorNotAllowWrite;
            return [self toErrorCallback:pCallBackId withCode:zipState withMessage:[self errorMsgWithCode:zipState]];
        }
        
        [PDRCore runInBackgroud:^{
            ZipArchive* pZipa = [[ZipArchive alloc] init];
            if (pZipa) {
                if ([pZipa UnzipOpenFile:pZipFile]) {
                    BOOL ret = [pZipa UnzipFileTo:pFileDic overWrite:YES];
                    if ( ret ) {
                        zipState = PGPluginOK;
                    }
                    [pZipa UnzipCloseFile];
                }
                [pZipa release];
            }
            [PDRCore runInMainThread:^{
                if ( PGPluginOK != zipState ) {
                    PDRPluginResult *result = nil;
                    result = [PDRPluginResult resultWithStatus:PDRCommandStatusError
                                          messageToErrorObject:zipState
                                                   withMessage:[self errorMsgWithCode:zipState]];
                    [self toCallback:pCallBackId withReslut:[result toJSONString]];
                } else {
                    PDRPluginResult *result = nil;
                    result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsInt:PGPluginOK];
                    [self toCallback:pCallBackId withReslut:[result toJSONString]];
                }
            }];
        }];
    }
}

- (void)compressImage:(PGMethod*)commands
{
    if ( commands ) {
        NSDictionary* options = [commands.arguments objectAtIndex:0];
        NSString* cbId = [commands.arguments objectAtIndex:1];
        __block PGZip *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PGZCompressImgOptions *compressParams = [PGZCompressImgOptions parse:options
                                                           withContext:weakSelf.appContext
                                                           withBaseUrl:[weakSelf.JSFrameContext.currenLocationHref stringByDeletingLastPathComponent]];
            if ( !compressParams.inputPath || !compressParams.outputPath ) {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorInvalidArgument];
                return;
            }
            BOOL dir = false;
            if ( ![[NSFileManager defaultManager] fileExistsAtPath:compressParams.inputPath isDirectory:&dir] || dir ) {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorFileNotFound];
                return;
            }
            
            if ( ![PTPathUtil allowsWritePath:compressParams.outputPath withContext:weakSelf.appContext] ) {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorNotAllowWrite];
                return;
            }
            
            NSString *outSuperPath = [compressParams.outputPath stringByDeletingLastPathComponent];
            [PTPathUtil ensureDirExist:outSuperPath];
            
            if ( !compressParams.isOverwrite
                && [[NSFileManager defaultManager] fileExistsAtPath:compressParams.outputPath] ) {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorFileExist];
                return;
            }
            NSData *output = nil;
            UIImage *outThubmnailImg = nil;
            UIImage *inputImg = [UIImage imageWithContentsOfFile:compressParams.inputPath];
            
            if ( !inputImg ) {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorFileNotFound];
                return;
            }
            inputImg = [inputImg adjustOrientationToup];
            [compressParams parseScaleSize:inputImg.size];
            switch ( compressParams.transform ) {
                case 90:
                case 270:
                    UIGraphicsBeginImageContext(CGSizeMake(compressParams.outputSize.height, compressParams.outputSize.width));
                    break;
                default:
                    UIGraphicsBeginImageContext(compressParams.outputSize);
                    break;
            }
            
            CGRect imageRect = CGRectMake(0.0, 0.0, compressParams.outputSize.width, compressParams.outputSize.height);
            CGContextRef contextRef = UIGraphicsGetCurrentContext();
            CGImageRef img = inputImg.CGImage;
            if ( img ) {
                CGContextTranslateCTM(contextRef, 0, imageRect.size.height);
                CGContextScaleCTM(contextRef, 1.0, -1.0);
                switch ( compressParams.transform ) {
                    case 90:
                        CGContextTranslateCTM(contextRef, 0, imageRect.size.height);
                        CGContextRotateCTM(contextRef, 270*M_PI/180);
                        break;
                    case 180:
                        CGContextTranslateCTM(contextRef, imageRect.size.width, imageRect.size.height);
                        CGContextRotateCTM(contextRef, compressParams.transform*M_PI/180);
                        break;
                    case 270:
                        CGContextTranslateCTM(contextRef, imageRect.size.height,imageRect.size.height-imageRect.size.width);
                        CGContextRotateCTM(contextRef, 90*M_PI/180);
                        break;
                    default:
                        break;
                }
                CGContextDrawImage( contextRef, imageRect, img);
                outThubmnailImg = UIGraphicsGetImageFromCurrentImageContext();
            }
            UIGraphicsEndImageContext();
            
            // clip image
            if ( outThubmnailImg )
            {
                CGSize clipOrgSize = outThubmnailImg.size;
                [compressParams parseClipSize:clipOrgSize];
                if ( !compressParams.isClipValid ) {
                    [weakSelf toErrorCallback:cbId withCode:PGZipErrorCompressImgClip];
                    return;
                }
                //CGRect imageRect = CGRectMake(0.0, 0.0, compressParams.clipRect.size.width, compressParams.clipRect.size.height);
                if ( !CGRectEqualToRect(CGRectMake(0, 0, clipOrgSize.width, clipOrgSize.height), compressParams.clipRect) ) {
                    //UIGraphicsBeginImageContext(compressParams.clipRect.size);
                    CGImageRef clipImgRef = CGImageCreateWithImageInRect(outThubmnailImg.CGImage, compressParams.clipRect);
                    //                    CGContextRef contextRef = UIGraphicsGetCurrentContext();
                    //                    CGContextTranslateCTM(contextRef, 0, imageRect.size.height);
                    //                    CGContextScaleCTM(contextRef, 1.0, -1.0);
                    //                    CGContextDrawImage( contextRef, imageRect, clipImgRef);
                    //                    outThubmnailImg = UIGraphicsGetImageFromCurrentImageContext();
                    //                    UIGraphicsEndImageContext();
                    outThubmnailImg = [UIImage imageWithCGImage:clipImgRef];
                    CGImageRelease(clipImgRef);
                }
            }
            if ( outThubmnailImg ) {
                if ( PGZCompressImgOutputFormatJPG == compressParams.outputFormat ) {
                    output = UIImageJPEGRepresentation(outThubmnailImg, compressParams.outputQuality);
                } else {
                    output = UIImagePNGRepresentation(outThubmnailImg);
                }
            }
            if ( output ) {
                [output writeToFile:compressParams.outputPath atomically:NO];
                PDRPluginResult *result = nil;
                NSDictionary *dict = @{@"path":[NSString stringWithFormat:@"file://%@", compressParams.outputPath],
                                       @"w":@(outThubmnailImg.size.width),
                                       @"h":@(outThubmnailImg.size.height),
                                       @"size":@(output.length)};
                result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary:dict];
                [weakSelf toCallback:cbId withReslut:[result toJSONString]];
            } else {
                [weakSelf toErrorCallback:cbId withCode:PGPluginErrorUnknown];
            }
        });
    }
}

- (NSString*)errorMsgWithCode:(int)errorCode {
    switch (errorCode) {
        case PGZipErrorCompressImgClip:
            return @"clip 区域 left 或top 参数错误";
        default:
            break;
    }
    return [super errorMsgWithCode:errorCode];
}

@end

@implementation PGZCompressImgOptions
@synthesize inputPath, outputPath, isOverwrite, outputFormat, outputQuality;
@synthesize clipRect, transform, outputSize, isClipValid;
+(PGZCompressImgOptions*)parse:(NSDictionary*)dict
                   withContext:(PDRCoreApp*)context
                   withBaseUrl:(NSString*)baseUrl {
    PGZCompressImgOptions *optins = [[[PGZCompressImgOptions alloc] init] autorelease];
    [optins parse:dict withContext:context withBaseUrl:baseUrl];
    return optins;
}
-(void)parse:(NSDictionary*)dict withContext:(PDRCoreApp*)context withBaseUrl:(NSString*)baseUrl {
    if ( [dict isKindOfClass:[NSDictionary class]] ) {
        NSString *jsInput = [dict objectForKey:@"src"];
        if ( [jsInput isKindOfClass:[NSString class]] ) {
           // self.inputPath = [PTPathUtil absolutePath:jsInput withContext:context];
            self.inputPath = [PTPathUtil h5Path2SysPath:jsInput basePath:baseUrl context:context];
        }
        if ( self.inputPath ) {
            [self parseFormat:[dict objectForKey:@"format"]];
            
            NSString *jsOutput = [dict objectForKey:@"dst"];
            if ( [jsOutput isKindOfClass:[NSString class]] ) {
                self.outputPath = [PTPathUtil absolutePath:jsOutput
                                                    prefix:@"compressImg_"
                                                    suffix:self.outputFormat == PGZCompressImgOutputFormatJPG ?@"jpg":@"png"
                                                   context:context];
               // self.outputPath = [PTPathUtil absolutePath:jsOutput withContext:context];
            } else {
                self.outputPath = [PTPathUtil uniqueNameInAppDocHasPrefix:@"compressImg_"
                                                                   suffix:self.outputFormat == PGZCompressImgOutputFormatJPG ?@"jpg":@"png"];
//                self.outputPath = [PTPathUtil absolutePath:@"_doc/zip/"
//                                                    prefix:@"compressImg_"
//                                                    suffix:self.outputFormat == PGZCompressImgOutputFormatJPG ?@"jpg":@"png"
//                                                   context:context];
            }
            
            NSNumber *jsOverwrite = [dict objectForKey:@"overwrite"];
            self.isOverwrite = false;
            if ([jsOverwrite isKindOfClass:[NSNumber class]]) {
                self.isOverwrite = [jsOverwrite boolValue];
            }
            NSNumber *jsRotate = [dict objectForKey:@"rotate"];
            self.transform = 0;
            if ([jsRotate isKindOfClass:[NSNumber class]]
                ||[jsRotate isKindOfClass:[NSString class]]) {
                int  rotate = [jsRotate intValue];
                if ( rotate == 90
                    ||rotate == 270
                    || rotate == 180 ) {
                    self.transform = rotate;
                }
            }
            
            NSNumber *jsQuality = [dict objectForKey:@"quality"];
            self.outputQuality = 0.5;
            if ([jsQuality isKindOfClass:[NSNumber class]]
                ||[jsQuality isKindOfClass:[NSString class]]) {
                self.outputQuality = [jsQuality intValue];
                self.outputQuality /= 100;
                if ( self.outputQuality < 0 ) {
                    self.outputQuality = 0.001;
                }
                if ( self.outputQuality > 1.0 ) {
                    self.outputQuality = 1;
                }
            }
            id jsWidth = [dict objectForKey:g_pdr_string_width];
            if ( jsWidth ) {
                _width = [jsWidth retain];
            }
            id jsHeight = [dict objectForKey:g_pdr_string_height];
            if ( jsHeight ) {
                _height = [jsHeight retain];
            }
            id jsClip = [dict objectForKey:@"clip"];
            if ( jsClip ) {
                _clip = [jsClip retain];
            }
        }
    }
}

- (void)parseFormat:(NSString*)jsFormat {
    NSString *pngF = @"png";
    NSString *jpgF = @"jpg";
    NSString *jpegF = @"jpeg";
   
    BOOL toError = false;
    self.outputFormat = PGZCompressImgOutputFormatJPG;
    if ([jsFormat isKindOfClass:[NSString class]]) {
        if ( NSOrderedSame == [pngF caseInsensitiveCompare:jsFormat] ) {
            self.outputFormat = PGZCompressImgOutputFormatPNG;
        } else if ( NSOrderedSame == [jpgF caseInsensitiveCompare:jsFormat]
                   ||NSOrderedSame == [jpegF caseInsensitiveCompare:jsFormat] ){
            self.outputFormat = PGZCompressImgOutputFormatJPG;
        } else {
            toError = true;
        }
    } else {
        toError = true;
    }
    if ( toError ) {
        NSString *ext = [self.inputPath pathExtension];
        if ( NSOrderedSame == [pngF caseInsensitiveCompare:ext] ) {
            self.outputFormat = PGZCompressImgOutputFormatPNG;
        } else if ( NSOrderedSame == [jpgF caseInsensitiveCompare:ext]
                   ||NSOrderedSame == [jpegF caseInsensitiveCompare:ext] ){
            self.outputFormat = PGZCompressImgOutputFormatJPG;
        }
    }
}

- (CGSize)parseWidth:(NSString*)jsWidth
              height:(NSString*)jsHeight
                size:(CGSize)inputImgSize
         defalutSize:(CGSize)defalutSize
        overflowSize:(CGSize)overflowSize
            overflow:(BOOL)overflow {
    CGSize outImgSize = defalutSize;
    CGFloat width, height = 0.0;
    BOOL isValidWidth = true;
    BOOL isValidHeight = true;
    
    if ( -1 == PT_Parse_GetMeasurement(jsWidth, inputImgSize.width, &width) ) {
        isValidWidth = false;
    }
    if ( overflow && width > overflowSize.width) {
        isValidWidth = false;
    }
    if ( width <= 0 ){ width = inputImgSize.width; }
    
    
    if (-1 == PT_Parse_GetMeasurement(jsHeight, inputImgSize.height, &height)) {
        isValidHeight = false;
    }
    if ( height <= 0 ){ height = inputImgSize.height; }
    if ( overflow && height > overflowSize.height) {
        isValidHeight = false;
    }

    if ( !isValidWidth ) {
        if ( isValidHeight ) {
            outImgSize.width = height/inputImgSize.height*inputImgSize.width;
        }
    } else {
        outImgSize.width = width;
    }
    if ( !isValidHeight ) {
        if ( isValidWidth ) {
            outImgSize.height = width/inputImgSize.width*inputImgSize.height;
        }
    } else {
        outImgSize.height = height;
    }
    return outImgSize;
}

- (void)parseClipSize:(CGSize)inputImgSize {
    self.isClipValid = true;
    CGRect imgClipRect = CGRectMake(0, 0, inputImgSize.width, inputImgSize.height);
    if ( [_clip isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *jsClip = (NSDictionary*)_clip;
        NSString *jsLeft = [jsClip objectForKey:g_pdr_string_left];
        NSString *jsTop = [jsClip objectForKey:g_pdr_string_top];
        CGFloat left = 0, top = 0;
        PT_Parse_GetMeasurement(jsLeft, inputImgSize.width, &left);
        PT_Parse_GetMeasurement(jsTop, inputImgSize.height, &top);
        if ( left >= 0 && left < inputImgSize.width
            && top >= 0 && top < inputImgSize.height) {
            imgClipRect.origin.x = left;
            imgClipRect.origin.y = top;
            imgClipRect.size.width -= left;
            imgClipRect.size.height -= top;
            CGSize setSize  = [self parseWidth:[jsClip objectForKey:g_pdr_string_width]
                                        height:[jsClip objectForKey:g_pdr_string_height]
                                          size:inputImgSize
                                   defalutSize:imgClipRect.size
                                  overflowSize:imgClipRect.size
                                      overflow:YES];
            imgClipRect.size = setSize;
        } else {
            self.isClipValid = false;
        }
    }
    self.clipRect = imgClipRect;
}

- (void)parseScaleSize:(CGSize)inputImgSize {

    self.outputSize = [self parseWidth:_width
                                height:_height
                                  size:inputImgSize
                           defalutSize:inputImgSize
                          overflowSize:CGSizeZero
                              overflow:NO];
}

-(void)dealloc {
    self.inputPath = nil;
    self.outputPath = nil;
    [_width release];
    [_height release];
    [_clip release];
    [super dealloc];
}

@end
