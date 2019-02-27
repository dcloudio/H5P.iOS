//
//  UPVideoSource.m
//  UPLiveSDKDemo
//
//  Created by 林港 on 16/8/15.
//  Copyright © 2016年 upyun.com. All rights reserved.
//

#import "UPVideoCapture.h"

#import "GPUImageFramebuffer.h"
#import "LFGPUImageBeautyFilter.h"


#import "UPCustonFilters.h"
#import "GPUImageBeautifyFilter.h"


@interface UPVideoCapture() {
    //videoCapture
    AVCaptureSession *_captureSession;
    AVCaptureDevicePosition _camaraPosition;

    NSError *_capturerError;
    
    //video preview
    UIView *_preview;
    UIViewContentMode _previewContentMode;
    
    //video size, capture size
    CGSize _capturerPresetLevelFrameCropSize;
    CGSize _presetVideoFrameRect;
    
    //camera focus
    CALayer *_focusLayer;
    
    UIInterfaceOrientation _previewOrientation;
    
    
    CGRect faceFrame;
    CGPoint leftEyeCenter, rightEyeCenter, mouthCenter;
}

@property (nonatomic, copy) NSString *sessionPreset;

//@property (nonatomic, strong) LFGPUImageBeautyFilter *beautifyFilter;
@property (nonatomic, strong) GPUImageCropFilter *cropfilter;
@property (nonatomic, strong) GPUImageTransformFilter *scaleFilter;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImageUIElement *uielement;
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) GPUImageFilter *blankFilter0;//空白滤镜
@property (nonatomic, strong) GPUImageFilter *blankFilter1;//空白滤镜
@property (nonatomic, strong) GPUImageFilter *blankFilter2;//空白滤镜




/// 没有处理的滤镜进行中转, 防止加水印的获取不到图像数据
@property (nonatomic, strong) GPUImageFilter *nFilter;

@property (nonatomic, strong) NSMutableArray *filtersArray;
@property (nonatomic, copy) WatermarkBlock watermarkBlock;

@end


@implementation UPVideoCapture


- (id)init {
    self = [super init];
    if (self) {
        _filtersArray = [NSMutableArray array];
        _camaraPosition = AVCaptureDevicePositionBack;
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        self.capturerPresetLevel = UPAVCapturerPreset_640x480;
        _capturerPresetLevelFrameCropSize = CGSizeZero;
        _fps = 24;
        _viewZoomScale = 1;
        _beautifyOn = NO;
        [self addNotifications];
    }
    return self;
}

- (void)gpuImageCameraSetup {
    [self cleanFilters];
    if (!_videoCamera) {
        // 初始化 GPUImageVideoCamera
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:_sessionPreset cameraPosition:_camaraPosition];
        // 设置横竖屏拍摄
        UIInterfaceOrientation videoCameraOrientation = UIInterfaceOrientationUnknown;
        switch (_videoOrientation) {
            case AVCaptureVideoOrientationPortrait:
                videoCameraOrientation = UIInterfaceOrientationPortrait;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                videoCameraOrientation = UIInterfaceOrientationPortraitUpsideDown;
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                videoCameraOrientation = UIInterfaceOrientationLandscapeRight;
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                videoCameraOrientation = UIInterfaceOrientationLandscapeLeft;
                break;
        }
        _videoCamera.outputImageOrientation = videoCameraOrientation;
        
        // 设置拍摄帧频
        _videoCamera.frameRate = _fps;
        
        // 设置拍摄预览画面
        if (!_preview) {
            _preview = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            _preview.backgroundColor = [UIColor blackColor];
        }
        
        _gpuImageView = [[GPUImageView alloc] initWithFrame:_preview.bounds];
        switch (_previewContentMode) {
            case UIViewContentModeScaleToFill:
                [_gpuImageView setFillMode:kGPUImageFillModeStretch];
                break;
            case UIViewContentModeScaleAspectFit:
                [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatio];
                break;
            case UIViewContentModeScaleAspectFill:
                [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
                break;
            default:
                [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatio];
                break;
        }
        [self previewRemoveGpuImageView];
        
        _gpuImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleBottomMargin;
        [_preview insertSubview:_gpuImageView atIndex:0];
    }
    
    //滤镜链
    //视频尺寸剪裁
    CGFloat cropW = _capturerPresetLevelFrameCropSize.width / _presetVideoFrameRect.width;
    CGFloat cropH = _capturerPresetLevelFrameCropSize.height / _presetVideoFrameRect.height;
    
    GPUImageOutput<GPUImageInput> *lastFilter;

    _blankFilter2 = [[GPUImageFilter alloc] init];
    [_videoCamera addTarget:_blankFilter2];

    _cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, cropW, cropH)];

    [_blankFilter2 addTarget:_cropfilter];
    lastFilter = _cropfilter;
    
    for (GPUImageOutput<GPUImageInput> *cusFilter in _filtersArray) {
        [lastFilter addTarget:cusFilter];
        _blankFilter1 = [[GPUImageFilter alloc] init];
        [cusFilter addTarget:_blankFilter1];
        lastFilter = _blankFilter1;
    }

    // 设置美颜滤镜
    if (_beautifyOn) {
        _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        [lastFilter addTarget:_beautifyFilter];
        lastFilter = _beautifyFilter;
    } else {
    }
    
    // 水印
    _nFilter = [[GPUImageFilter alloc] init];
    
    if (!_watermarkView) {
        [lastFilter addTarget:_nFilter];
        [_nFilter addTarget:_gpuImageView];
        
    } else {
        _uielement = [[GPUImageUIElement alloc] initWithView:_watermarkView];
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        _blankFilter0 = [[GPUImageFilter alloc] init];
        [lastFilter addTarget:_blankFilter0];
        [_blankFilter0 addTarget:_blendFilter];
        [_uielement addTarget:_blendFilter];
        [_blendFilter addTarget:_nFilter];
        [lastFilter addTarget:_gpuImageView];
        
        __weak GPUImageUIElement *weakUielement = _uielement;
        [lastFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *outPut, CMTime time) {
            if (_watermarkBlock) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    _watermarkBlock();
                });
            }
            [weakUielement update];
        }];
    }
    [self outputPixelBuffer];
    //横屏旋转和前置拍摄镜面效果
    [self needFlip];

}

/// 去除滤镜链
- (void)cleanFilters {
    [_beautifyFilter removeAllTargets];
    [_cropfilter removeAllTargets];
    [_videoCamera removeAllTargets];
    [_uielement removeAllTargets];
    [_nFilter removeAllTargets];
    [_blendFilter removeAllTargets];
    [_blankFilter0 removeAllTargets];
    
    for (GPUImageOutput<GPUImageInput> *cusFilter in _filtersArray) {
        [cusFilter removeAllTargets];
    }
}

/// 设置图像获取
- (void)outputPixelBuffer {
    __weak typeof(self) weakself = self;
    //设置视频结果回调
    [_nFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *outPut, CMTime time) {
        GPUImageFramebuffer *imageFramebuffer = outPut.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        
        size_t width_o = CVPixelBufferGetWidth(pixelBuffer);
        size_t height_o = CVPixelBufferGetHeight(pixelBuffer);
        OSType format_o = CVPixelBufferGetPixelFormatType(pixelBuffer);

        NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSDictionary dictionary],kCVPixelBufferIOSurfacePropertiesKey,nil];

        CVPixelBufferRef pixelBuffer_c;
        CVPixelBufferCreate(NULL, width_o, height_o, format_o, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer_c);
       
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferLockBaseAddress(pixelBuffer_c, 0);
        void *baseAddress_o = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        size_t dataSize_o = CVPixelBufferGetDataSize(pixelBuffer);
        void *target = CVPixelBufferGetBaseAddress(pixelBuffer_c);
        memcpy(target, baseAddress_o, dataSize_o);
        //int bytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer_c, 0);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        if (weakself.delegate) {
            [weakself.delegate didCapturePixelBuffer:pixelBuffer_c];
        }
    }];
}

/// 横屏旋转和前置拍摄镜面效果
- (void)needFlip {
    BOOL needRotation = NO;
    
    float  pviewOrientation_ = 0;
    float  videoOrientation_ = 0;
    switch (_previewOrientation) {
        case UIInterfaceOrientationUnknown: pviewOrientation_ =  0;
            break;
        case UIInterfaceOrientationPortrait: pviewOrientation_ =  0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown: pviewOrientation_ =  M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft: pviewOrientation_ =  M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight: pviewOrientation_ = - M_PI_2;
            break;
        default: pviewOrientation_ =  0;
            break;
    }
    
    switch (_videoOrientation) {
        case AVCaptureVideoOrientationPortrait: videoOrientation_ =  0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown: videoOrientation_ =  M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft: videoOrientation_ =  M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight: videoOrientation_ = - M_PI_2;
            break;
        default: videoOrientation_ =  0;
            break;
    }
    
    if (pviewOrientation_ != videoOrientation_) {
        needRotation = YES;
    }
    
    if (needRotation) {
        
//更换了横屏拍摄模式，这段代码废弃。现在的横屏拍摄模式需要 vc 的横屏配合实现。
        
//        float deltaR = pviewOrientation_ - videoOrientation_;
//        _gpuImageView.transform = CGAffineTransformMakeRotation(deltaR);
//        //长宽需要对调
//        if (fabs(deltaR) >= M_PI_4 && fabs(deltaR) <= (M_PI_4 + M_PI_2)) {
//            CGRect oldRect = _gpuImageView.frame;
//            _gpuImageView.frame = CGRectMake(0, 0, oldRect.size.height, oldRect.size.width);
//        }
    }
    
    BOOL needFlip = NO;
    if (_camaraPosition == AVCaptureDevicePositionFront) {
        needFlip = YES;
    }
    if (needFlip) {
        [_gpuImageView setInputRotation:kGPUImageFlipHorizonal atIndex:0];
    }
}

- (void)switchCamera{
    AVCaptureDevicePosition destPos = AVCaptureDevicePositionBack;
     if(_camaraPosition == AVCaptureDevicePositionFront) {
         destPos = AVCaptureDevicePositionBack;
     }else{
         destPos = AVCaptureDevicePositionFront;
     }    
    [self setCamaraPosition:destPos];
}

- (void)setCamaraPosition:(AVCaptureDevicePosition)camaraPosition {
    if (AVCaptureDevicePositionUnspecified == camaraPosition) {
        return;
    }
    if (_camaraPosition == camaraPosition) {
        return;
    }
    _camaraPosition = camaraPosition;
    
    if (!_videoCamera) {
        return;
    }
    
    [self.videoCamera stopCameraCapture];
    _videoCamera = nil;
    [self gpuImageCameraSetup];
    [self.videoCamera startCameraCapture];
}

- (AVCaptureSession *)captureSession {
    return self.videoCamera.captureSession;
}


- (void)resetCapturerPresetLevelFrameSizeWithCropRect:(CGSize)cropRect {
    
    BOOL portrait = YES;
    if (_videoOrientation == AVCaptureVideoOrientationLandscapeRight
        || _videoOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        portrait = NO;
    }
    
    CGFloat presetWidth = 640;
    CGFloat presetHeight = 480;
    switch (_capturerPresetLevel) {
        case UPAVCapturerPreset_480x360:{
            presetWidth = 480;
            presetHeight = 360;
            break;
        }
        case UPAVCapturerPreset_640x480:{
            presetWidth = 640;
            presetHeight = 480;
            break;
        }
        case UPAVCapturerPreset_960x540:{
            presetWidth = 960;
            presetHeight = 540;
            break;
        }
        case UPAVCapturerPreset_1280x720:{
            presetWidth = 1280;
            presetHeight = 720;
            break;
        }
    }
    
    if (portrait) {
        CGFloat w = MIN(presetHeight, presetWidth);
        CGFloat h = MAX(presetHeight, presetWidth);
        presetWidth = w;
        presetHeight = h;
    }
    _presetVideoFrameRect = CGSizeMake(presetWidth, presetHeight);
    if (cropRect.width > presetWidth
        || cropRect.height > presetHeight) {
        //超出范围，设置不成功；
        _capturerPresetLevelFrameCropSize = _presetVideoFrameRect;
    } else {
        _capturerPresetLevelFrameCropSize = cropRect;
    }
    
    if (_capturerPresetLevelFrameCropSize.width * _capturerPresetLevelFrameCropSize.height == 0) {
        //大小为0，设置不成功；
        _capturerPresetLevelFrameCropSize = _presetVideoFrameRect;
    }
}

- (void)setCapturerPresetLevelFrameCropRect:(CGSize)capturerPresetLevelFrameCropSize {
    [self resetCapturerPresetLevelFrameSizeWithCropRect:capturerPresetLevelFrameCropSize];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    _videoOrientation = videoOrientation;
    UIInterfaceOrientation outOrientation = UIInterfaceOrientationPortrait;
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            outOrientation = UIInterfaceOrientationPortrait;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            outOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            outOrientation = UIInterfaceOrientationLandscapeRight;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            outOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        default:
            break;
    }
    [_videoCamera setOutputImageOrientation:outOrientation];
    [self resetCapturerPresetLevelFrameSizeWithCropRect:_capturerPresetLevelFrameCropSize];
}

- (void)setCapturerPresetLevel:(UPAVCapturerPresetLevel)capturerPresetLevel {
    _capturerPresetLevel = capturerPresetLevel;
    [self resetCapturerPresetLevelFrameSizeWithCropRect:_capturerPresetLevelFrameCropSize];
    
    switch (_capturerPresetLevel) {
        case UPAVCapturerPreset_480x360:{
            _sessionPreset = AVCaptureSessionPresetMedium;
            break;
        }
        case UPAVCapturerPreset_640x480:{
            _sessionPreset = AVCaptureSessionPreset640x480;
            break;
        }
        case UPAVCapturerPreset_960x540:{
            _sessionPreset = AVCaptureSessionPresetiFrame960x540;
            break;
        }
        case UPAVCapturerPreset_1280x720:{
            _sessionPreset = AVCaptureSessionPreset1280x720;
            break;
        }
        default:{
            _sessionPreset = AVCaptureSessionPreset640x480;
            break;
        }
    }
}

- (void)setFps:(int32_t)fps{
    _fps = fps;
    if (_videoCamera) {
        _videoCamera.frameRate = fps;
    }
}

- (void)setBeautifyOn:(BOOL)beautifyOn {
    _beautifyOn = beautifyOn;
    [self doSwitchFilters];
}

- (void)setWatermarkView:(UIView *)watermarkView Block:(WatermarkBlock)block {
    _watermarkView = watermarkView;
    _watermarkBlock = block;
}

- (UIView *)previewWithFrame:(CGRect)frame contentMode:(UIViewContentMode)mode {
    _previewContentMode = mode;
    _preview = [[UIView alloc] initWithFrame:frame];
    _preview.frame = frame;
    _previewOrientation = UIInterfaceOrientationPortrait;
#ifndef UPYUN_APP_EXTENSIONS
    //记录preview的UI方向，如果UI方向和拍摄方向不一致时候，拍摄画面需要旋转
    _previewOrientation = [[UIApplication sharedApplication] statusBarOrientation];
#endif
    [self preViewAddTapGesture];
    return _preview;
}

- (void)previewRemoveGpuImageView {
    for (UIView *view in _preview.subviews) {
        if ([view isKindOfClass:[GPUImageView class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)start {
    [self.videoCamera stopCameraCapture];
    _videoCamera = nil;
    [self gpuImageCameraSetup];
    [self.videoCamera startCameraCapture];
#ifndef UPYUN_APP_EXTENSIONS
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
#endif
}

- (void)stop {
    [self cleanFilters];
    [self.videoCamera stopCameraCapture];
    [self previewRemoveGpuImageView];
#ifndef UPYUN_APP_EXTENSIONS
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
#endif
}

- (void)restart {
    [self.videoCamera stopCameraCapture];
    _videoCamera = nil;
    [self gpuImageCameraSetup];
    [self.videoCamera startCameraCapture];
}

- (void)dealloc {
    
}

- (void)setCamaraTorchOn:(BOOL)camaraTorchOn {
    _camaraTorchOn = camaraTorchOn;
    AVCaptureTorchMode torchMode = camaraTorchOn ? AVCaptureTorchModeOn:AVCaptureTorchModeOff;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode: torchMode];
        [device unlockForConfiguration];
    }
}

- (void)setViewZoomScale:(CGFloat)viewZoomScale {
    if (self.videoCamera && self.videoCamera.inputCamera) {
        AVCaptureDevice *device = (AVCaptureDevice *)self.videoCamera.inputCamera;
        if ([device lockForConfiguration:nil]) {
            device.videoZoomFactor = viewZoomScale;
            [device unlockForConfiguration];
            _viewZoomScale = viewZoomScale;
        }
    }
}

#pragma mark-- filter 滤镜

- (void)doSwitchFilters {
    if (_videoCamera) {
        [self gpuImageCameraSetup];
    }
}

- (void)cleanFilterArray {
    for (GPUImageOutput<GPUImageInput> *item in _filtersArray) {
        [item removeAllTargets];
    }
    [_filtersArray removeAllObjects];
}

- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter {
    [self cleanFilterArray];
    if (filter) {
        [_filtersArray addObject:filter];
    }
    [self doSwitchFilters];
}

- (void)setFilterName:(UPCustomFilter)filterName {
    [self cleanFilterArray];
    [self addFilterName:filterName];
    [self doSwitchFilters];
}

- (void)setFilters:(NSArray *)filters {
    [self cleanFilterArray];
    _filtersArray = [filters mutableCopy];
    [self doSwitchFilters];
}

- (void)setFilterNames:(NSArray *)filterNames {
    [self cleanFilterArray];
    for (NSString *filterName in filterNames) {
        UPCustomFilter name = filterName.integerValue;
        [self addFilterName:name];
    }
    [self doSwitchFilters];
}


- (void)addFilterName:(UPCustomFilter)filterName {
    
    
    GPUImageOutput<GPUImageInput> *filter = nil;
    
    
    switch (filterName) {
        case UPCustomFilter1977:{
            filter = [[FW1977Filter alloc] init];
            break;
        }
        case UPCustomFilterHefe:{
            filter = [[FWHefeFilter alloc] init];
            break;
        }
        case UPCustomFilterRise:{
            filter = [[FWRiseFilter alloc] init];
            break;
        }
        case UPCustomFilterSutro:{
            filter = [[FWSutroFilter alloc] init];
            break;
        }
        case UPCustomFilterHudson:{
            filter = [[FWHudsonFilter alloc] init];
            break;
        }
        case UPCustomFilterLomofi:{
            filter = [[FWLomofiFilter alloc] init];
            break;
        }
        case UPCustomFilterSierra:{
            filter = [[FWSierraFilter alloc] init];
            break;
        }
        case UPCustomFilterSketch:{
            filter = [[GPUImageSketchFilter alloc] init];
            break;
        }
        case UPCustomFilterWalden:{
            filter = [[FWWaldenFilter alloc] init];
            break;
        }
        case UPCustomFilterXproII:{
            filter = [[FWXproIIFilter alloc] init];
            break;
        }
        case UPCustomFilterBrannan:{
            filter = [[FWBrannanFilter alloc] init];
            break;
        }
        case UPCustomFilterInkwell:{
            filter = [[FWInkwellFilter alloc] init];
            break;
        }
        case UPCustomFilterToaster:{
            filter = [[FWToasterFilter alloc] init];
            break;
        }
        case UPCustomFilterAmatorka:{
            filter = [[GPUImageAmatorkaFilter alloc] init];
            break;
        }
        case UPCustomFilterValencia:{
            filter = [[FWValenciaFilter alloc] init];
            break;
        }
        case UPCustomFilterEarlybird:{
            filter = [[FWEarlybirdFilter alloc] init];
            break;
        }
        case UPCustomFilterNashville:{
            filter = [[FWNashvilleFilter alloc] init];
            break;
        }
        case UPCustomFilterLordKelvin:{
            filter = [[FWLordKelvinFilter alloc] init];
            break;
        }
        case UPCustomFilterMissEtikate:{
            filter = [[GPUImageMissEtikateFilter alloc] init];
            break;
        }
        case UPCustomFilterSoftElegance:{
            /// 这个滤镜和 美颜, 水印冲突
//            filter = [[GPUImageSoftEleganceFilter alloc] init];
            filter = [[GPUImageFilter alloc] init];
            break;
        }
    }
    
    if (![_filtersArray containsObject:filter] && filter) {
        [_filtersArray addObject:filter];
    } else {
        NSLog(@"filter ==nil or filterNamerange error ==%ld", (long)filterName);
    }
}

#pragma mark-- 点击自动对焦

- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr {
    if (tgr.state == UIGestureRecognizerStateRecognized
        && (_focusLayer == NO || _focusLayer.hidden)) {
    CGPoint location = [tgr locationInView:_preview];
    [self setfocusImage];
    [self layerAnimationWithPoint:location];
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:self.camaraPosition];
    
    CGSize frameSize = _preview.frame.size;
    
    if (self.camaraPosition == AVCaptureDevicePositionFront) {
        location.x = frameSize.width - location.x;
    }
    
    CGPoint pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported]
        && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            [device setFocusPointOfInterest:pointOfInterest];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            
            if([device isExposurePointOfInterestSupported]
               && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [device unlockForConfiguration];
        } else {
            NSLog(@"ERROR = %@", error);
        }
    }
}
}

- (void)setfocusImage {
    
    if (_focusLayer) {
        _focusLayer.hidden = YES;
        [_preview.layer addSublayer:_focusLayer];
        return;
    }
    
    UIImage *focusImage = [UIImage imageNamed:@"focus"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, focusImage.size.width, focusImage.size.height)];
    imageView.image = focusImage;
    CALayer *layer = imageView.layer;
    layer.hidden = YES;
    _focusLayer = layer;
    [_preview.layer addSublayer:layer];
}

- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        
        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.delegate = self;
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
        
        // 0.5秒钟延时
        [self performSelector:@selector(focusLayerNormal) withObject:self afterDelay:0.5f];
    }
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [_focusLayer removeFromSuperlayer];
    
}

- (void)focusLayerNormal {
    _preview.userInteractionEnabled = YES;
    _focusLayer.hidden = YES;
}
/// 增加点击对焦事件
- (void)preViewAddTapGesture {
    UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    singleFingerOne.numberOfTouchesRequired = 1; //手指数
    singleFingerOne.numberOfTapsRequired = 1; //tap次数
    [_preview addGestureRecognizer:singleFingerOne];
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    } return nil;
}

- (void)addNotifications {
#ifndef UPYUN_APP_EXTENSIONS
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:[UIApplication sharedApplication]];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:[UIApplication sharedApplication]];
#endif
}


- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.videoCamera pauseCameraCapture];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.videoCamera resumeCameraCapture];
}

@end
