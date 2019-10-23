//
//  TZAssetCell.h
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    TZAssetCellTypePhoto = 0,
    TZAssetCellTypeLivePhoto,
    TZAssetCellTypePhotoGif,
    TZAssetCellTypeVideo,
    TZAssetCellTypeAudio,
} TZAssetCellType;

@class DCTZAssetModel;
@interface DCTZAssetCell : UICollectionViewCell
@property (weak, nonatomic) UIButton *selectPhotoButton;
@property (weak, nonatomic) UIButton *cannotSelectLayerButton;
@property (nonatomic, strong) DCTZAssetModel *model;
@property (assign, nonatomic) NSInteger index;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL);
@property (nonatomic, assign) TZAssetCellType type;
@property (nonatomic, assign) BOOL allowPickingGif;
@property (nonatomic, assign) BOOL allowPickingMultipleVideo;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic, assign) int32_t imageRequestID;

@property (nonatomic, strong) UIImage *photoSelImage;
@property (nonatomic, strong) UIImage *photoDefImage;

@property (nonatomic, assign) BOOL showSelectBtn;
@property (assign, nonatomic) BOOL allowPreview;
@property (assign, nonatomic) BOOL useCachedImage;

@property (nonatomic, copy) void (^assetCellDidSetModelBlock)(DCTZAssetCell *cell, UIImageView *imageView, UIImageView *selectImageView, UILabel *indexLabel, UIView *bottomView, UILabel *timeLength, UIImageView *videoImgView);
@property (nonatomic, copy) void (^assetCellDidLayoutSubviewsBlock)(DCTZAssetCell *cell, UIImageView *imageView, UIImageView *selectImageView, UILabel *indexLabel, UIView *bottomView, UILabel *timeLength, UIImageView *videoImgView);
@end


@class DCTZAlbumModel;
@interface DCTZAlbumCell : UITableViewCell
@property (nonatomic, strong) DCTZAlbumModel *model;
@property (weak, nonatomic) UIButton *selectedCountButton;

@property (nonatomic, copy) void (^albumCellDidSetModelBlock)(DCTZAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel);
@property (nonatomic, copy) void (^albumCellDidLayoutSubviewsBlock)(DCTZAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel);
@end


@interface TZAssetCameraCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end
