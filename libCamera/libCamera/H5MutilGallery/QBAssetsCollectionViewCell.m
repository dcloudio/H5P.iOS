//
//  QBAssetsCollectionViewCell.m
//  QBImagePickerController
//
//  Created by Tanaka Katsuma on 2013/12/31.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsCollectionViewCell.h"

// Views
#import "QBAssetsCollectionOverlayView.h"

@interface QBAssetsVideoMarkView : UIView
@property (nonatomic, strong) UIImage *markImage;
@end

@implementation QBAssetsVideoMarkView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.4);
    CGContextFillRect(context, self.bounds);
    
    CGRect markImageRect = self.bounds;
    CGSize markImageSize = self.markImage.size;
    markImageRect.size.width = self.bounds.size.height*markImageSize.width/markImageSize.height;
    markImageRect.origin.x = (self.bounds.size.width - markImageRect.size.width)/2;
   // [self.markImage drawInRect:CGRectInset(markImageRect, 1,1)];
    [self.markImage drawInRect:markImageRect];
}

@end

@interface QBAssetsCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) QBAssetsVideoMarkView *videoMakerView;
@property (nonatomic, strong) QBAssetsCollectionOverlayView *overlayView;

@end

@implementation QBAssetsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.showsOverlayViewWhenSelected = YES;
        
        // Create a image view
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:imageView];
        self.imageView = imageView;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // Show/hide overlay view
    if (selected && self.showsOverlayViewWhenSelected) {
        [self hideOverlayView];
        [self showOverlayView];
    } else {
        [self hideOverlayView];
    }
}

- (void)showOverlayView
{
    QBAssetsCollectionOverlayView *overlayView = [[QBAssetsCollectionOverlayView alloc] initWithFrame:self.contentView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.contentView addSubview:overlayView];
    self.overlayView = overlayView;
}

- (void)hideOverlayView
{
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
}

- (void)showVideoMarkOverlay {
    QBAssetsVideoMarkView *markView = [[QBAssetsVideoMarkView alloc] initWithFrame:self.contentView.bounds];
    markView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    markView.markImage = [UIImage imageNamed:@"PandoraApi.bundle/plugin/gallery/video.png"];
    markView.backgroundColor = [UIColor clearColor];
    CGRect subRect = self.contentView.bounds;
    subRect.origin.y = subRect.size.height * 0.8;
    subRect.size.height *= 0.2f;
    markView.frame = subRect;
    [self.contentView addSubview:markView];
    self.videoMakerView = markView;
}


#pragma mark - Accessors

- (void)setAsset:(ALAsset *)asset
{
    _asset = asset;
    // Update view
    self.imageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
    NSString *assetType = [asset valueForProperty:ALAssetPropertyType];
//    ALAssetRepresentation *asset1 = [asset defaultRepresentation];
//    NSLog(@"%@", asset1.metadata);
    if ( [ALAssetTypeVideo isEqualToString:assetType]) {
        [self showVideoMarkOverlay];
    }
}

@end
