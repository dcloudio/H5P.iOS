//
//  GPUImageBeautifyFilter.m
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/28.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "GPUImageBeautifyFilter.h"

// Internal CombinationFilter(It should not be used outside)
@interface GPUImageCombinationFilter : GPUImageThreeInputFilter
{
    GLint smoothDegreeUniform;
}

@property (nonatomic, assign) CGFloat intensity;
/// 边缘检测调整
@property (nonatomic, assign)CGFloat cannyEdgeLevel;

@end

NSString *const kGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 void main()
 {
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3,textureCoordinate3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     }
     else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     gl_FragColor = smooth;
 }
 );

@implementation GPUImageCombinationFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kGPUImageBeautifyFragmentShaderString]) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"];
    }
    self.intensity = 0.6;
    return self;
}

- (void)setIntensity:(CGFloat)intensity {
    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end

@implementation GPUImageBeautifyFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    
    //defalut value
    _level = 0.6;
    _bilateralLevel = 4.0;
    _saturationLevel = 1.1;
    _brightnessLevel = 1.1;
    
    // First pass: face smoothing filter
    _bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    _bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:_bilateralFilter];// 磨皮
    
    // Second pass: edge detection
    //cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    //[self addFilter:cannyEdgeFilter];// 边缘检测
    _sobelEdgeFilter = [[GPUImageSobelEdgeDetectionFilter alloc]init];
    [self addFilter:_sobelEdgeFilter];
    
    
    // Third pass: combination bilateral, edge detection and origin
    _combinationFilter = [[GPUImageCombinationFilter alloc] init];
    [self addFilter:_combinationFilter];
    
    // Adjust HSB
    _hsbFilter = [[GPUImageHSBFilter alloc] init];
    [_hsbFilter adjustBrightness:1.1]; // 亮度
    [_hsbFilter adjustSaturation:1.1]; // 饱和度
    [_bilateralFilter addTarget:_combinationFilter];
    //[cannyEdgeFilter addTarget:_combinationFilter];
    [_sobelEdgeFilter addTarget:_combinationFilter];
    
    
    [_combinationFilter addTarget:_hsbFilter];
    
    //self.initialFilters = [NSArray arrayWithObjects:_bilateralFilter,cannyEdgeFilter,_combinationFilter,nil];
    self.initialFilters = [NSArray arrayWithObjects:_bilateralFilter,_sobelEdgeFilter,_combinationFilter,nil];

    self.terminalFilter = _hsbFilter;
    
    return self;
}

- (void)setLevel:(CGFloat)level {
    _level = level;
    [_combinationFilter setIntensity:level];
}

- (void)setBilateralLevel:(CGFloat)bilateralLevel {
    _bilateralLevel = bilateralLevel;
    _bilateralFilter.distanceNormalizationFactor = _bilateralLevel;
}

- (void)setCannyEdgeLevel:(CGFloat)cannyEdgeLevel {
    
}

- (void)setBrightnessLevel:(CGFloat)brightnessLevel {
    _brightnessLevel = brightnessLevel;
    [self resetHsb];
}

- (void)setSaturationLevel:(CGFloat)saturationLevel {
    _saturationLevel = saturationLevel;
    [self resetHsb];
}

- (void)resetHsb {
    [_hsbFilter reset];
    [_hsbFilter adjustBrightness:_brightnessLevel]; // 亮度
    [_hsbFilter adjustSaturation:_saturationLevel]; // 饱和度
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            if (currentFilter == _combinationFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter == _combinationFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end
