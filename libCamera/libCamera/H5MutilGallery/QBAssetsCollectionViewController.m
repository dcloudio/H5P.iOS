//
//  QBAssetsCollectionViewController.m
//  QBImagePickerController
//
//  Created by Tanaka Katsuma on 2013/12/31.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBAssetsCollectionViewController.h"

// Views
#import "QBAssetsCollectionViewCell.h"
#import "QBAssetsCollectionFooterView.h"

@interface QBAssetsCollectionViewController () {
}

@property (nonatomic, strong) NSMutableArray *assets;

@property (nonatomic, assign) NSInteger numberOfPhotos;
@property (nonatomic, assign) NSInteger numberOfVideos;
//@property (nonatomic, assign) BOOL setSelectAsset;

@end

@implementation QBAssetsCollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    
    if (self) {
        //self.setSelectAsset = true;
        // View settings
        self.collectionView.backgroundColor = [UIColor whiteColor];
        self.wantsFullScreenLayout = TRUE;
        // Register cell class
        [self.collectionView registerClass:[QBAssetsCollectionViewCell class]
                forCellWithReuseIdentifier:@"AssetsCell"];
        [self.collectionView registerClass:[QBAssetsCollectionFooterView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:@"FooterView"];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Scroll to bottom
    CGFloat topInset = 0.0f;
    if ( [self respondsToSelector:@selector(edgesForExtendedLayout)] ) {
        topInset = ((self.edgesForExtendedLayout && UIRectEdgeTop) && (self.collectionView.contentInset.top == 0)) ? (20.0 + 44.0) : 0.0;
    } else {
        UIEdgeInsets insets = {64,0,0,0};
        self.collectionView.contentInset = insets;
        self.collectionView.scrollIndicatorInsets = insets;
    }
    [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.collectionViewLayout.collectionViewContentSize.height - self.collectionView.frame.size.height + topInset)
                                 animated:NO];
    // Validation
    if (self.allowsMultipleSelection) {
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:self.imagePickerController.selectedAssetURLs.count];
    }
}

- (void)viewDidAppear:(BOOL)animated {
//    if ( self.setSelectAsset ) {
//        NSArray *needSelectAssertUrls = self.imagePickerController.selectedAssetURLs;
//        for ( NSURL *assetUrl in needSelectAssertUrls ) {
//            for ( NSInteger idx = 0; idx < [self.assets count]; idx++ ) {
//                NSURL *testAssetURL = [self.assets[idx] valueForProperty:ALAssetPropertyAssetURL];
//                if ( [assetUrl isEqual:testAssetURL] ) {
//                    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
//                                                      animated:YES
//                                                scrollPosition:UICollectionViewScrollPositionNone];
//                }
//            }
//        }
//        
//        self.setSelectAsset = false;
//    }
}


#pragma mark - Accessors

- (void)setFilterType:(QBImagePickerControllerFilterType)filterType
{
    _filterType = filterType;
    
    // Set assets filter
    [self.assetsGroup setAssetsFilter:ALAssetsFilterFromQBImagePickerControllerFilterType(self.filterType)];
}

- (void)setAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    _assetsGroup = assetsGroup;
    
    // Set title
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    // Get the number of photos and videos
    [self.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    self.numberOfPhotos = self.assetsGroup.numberOfAssets;
    
    [self.assetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
    self.numberOfVideos = self.assetsGroup.numberOfAssets;
    
    // Set assets filter
    [self.assetsGroup setAssetsFilter:ALAssetsFilterFromQBImagePickerControllerFilterType(self.filterType)];
    
    // Load assets
    self.assets = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [weakSelf.assets addObject:result];
        }
    }];
    
    // Update view
    [self.collectionView reloadData];
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    self.collectionView.allowsMultipleSelection = allowsMultipleSelection;
    
    // Show/hide done button
    if (allowsMultipleSelection) {
//        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
//        UIBarButtonItem *tipButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"(%lu)", (unsigned long)self.imagePickerController.selectedAssetURLs.count]
//                                                                      style:UIBarButtonItemStyleDone
//                                                                     target:nil
//                                                                     action:nil];
//        //tipButton.enabled = false;
//        tipButton.tintColor = [UIColor redColor];
//        NSArray *actionButtonItems = @[tipButton, doneButton];
//        self.navigationItem.rightBarButtonItems = actionButtonItems;
        
     //   UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        NSUInteger selectCount = self.imagePickerController.selectedAssetURLs.count;
        NSString *doneTititle = selectCount ? [NSString stringWithFormat:@"确定(%ld)",(unsigned long)selectCount] : @"确定";
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:doneTititle style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
        [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
    } else {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        [self.navigationItem setRightBarButtonItem:cancelButton animated:NO];
        //[self.navigationItem setRightBarButtonItem:nil animated:NO];
    }
}

- (BOOL)allowsMultipleSelection
{
    return self.collectionView.allowsMultipleSelection;
}

#pragma mark - Actions

- (void)done:(id)sender
{
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewControllerDidFinishSelection:)]) {
        [self.delegate assetsCollectionViewControllerDidFinishSelection:self];
    }
}

- (void)cancel:(id)sender
{
    // Delegate
    if (self.imagePickerController.delegate && [self.imagePickerController.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [self.imagePickerController.delegate imagePickerControllerDidCancel:self.imagePickerController];
    }
}

#pragma mark - Managing Selection

- (void)selectAssetHavingURL:(NSURL *)URL
{
    for (NSInteger i = 0; i < self.assets.count; i++) {
        ALAsset *asset = [self.assets objectAtIndex:i];
        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        
        if ([assetURL isEqual:URL]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
            return;
        }
    }
}


#pragma mark - Validating Selections

- (BOOL)validateNumberOfSelections:(NSUInteger)numberOfSelections
{
    NSUInteger minimumNumberOfSelection = MAX(1, self.minimumNumberOfSelection);
    BOOL qualifiesMinimumNumberOfSelection = (numberOfSelections >= minimumNumberOfSelection);
    
    BOOL qualifiesMaximumNumberOfSelection = YES;
    if (!self.allowsAllSelection && minimumNumberOfSelection <= self.maximumNumberOfSelection) {
        qualifiesMaximumNumberOfSelection = (numberOfSelections <= self.maximumNumberOfSelection);
    }
    
    return (qualifiesMinimumNumberOfSelection && qualifiesMaximumNumberOfSelection);
}

- (BOOL)validateMaximumNumberOfSelections:(NSUInteger)numberOfSelections
{
   // return [self.imagePickerController validateNumberOfSelections:numberOfSelections];
    NSUInteger minimumNumberOfSelection = MAX(1, self.minimumNumberOfSelection);
    
    if ( !self.allowsAllSelection && minimumNumberOfSelection <= self.maximumNumberOfSelection) {
        return (numberOfSelections <= self.maximumNumberOfSelection);
    }
    
    return YES;
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetsGroup.numberOfAssets;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBAssetsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AssetsCell" forIndexPath:indexPath];
    cell.showsOverlayViewWhenSelected = self.allowsMultipleSelection;
    
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    cell.asset = asset;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(collectionView.bounds.size.width, 46.0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionFooter) {
        QBAssetsCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                      withReuseIdentifier:@"FooterView"
                                                                                             forIndexPath:indexPath];
        
        switch (self.filterType) {
            case QBImagePickerControllerFilterTypeNone:
                footerView.textLabel.text = [NSString stringWithFormat:@"%ld 照片, %ld 视频",(long)self.numberOfPhotos, (long)self.numberOfVideos ];
                break;
                
            case QBImagePickerControllerFilterTypePhotos:
                footerView.textLabel.text = [NSString stringWithFormat:@"%ld 照片", (long)self.numberOfPhotos ];
                break;
                
            case QBImagePickerControllerFilterTypeVideos:
                footerView.textLabel.text = [NSString stringWithFormat:@"%ld 视频", (long)self.numberOfVideos];
                break;
        }
        
        return footerView;
    }
    
    return nil;
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM() ) {
        CGFloat width = MIN(self.view.frame.size.width, self.view.frame.size.height);
        return CGSizeMake((width-10)/4, (width-10)/4);
    }
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGFloat width = MIN(frame.size.width, frame.size.height);
    return CGSizeMake((width-10)/4, (width-10)/4);
    return CGSizeMake(91.25, 91.25);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 2, 2);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldSelect = [self validateMaximumNumberOfSelections:(self.imagePickerController.selectedAssetURLs.count + 1)];
    if ( !shouldSelect ) {
        // Delegate
        if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewControllerOnmaxed:)]) {
            [self.delegate assetsCollectionViewControllerOnmaxed:self];
        }
    }
    return shouldSelect;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    // Validation
    if (self.allowsMultipleSelection) {
        //UIBarButtonItem *t = [self.navigationItem.rightBarButtonItems objectAtIndex:1];
        NSUInteger selectCount = self.imagePickerController.selectedAssetURLs.count+1;
        NSString *doneTititle = selectCount ? [NSString stringWithFormat:@"确定(%ld)",(unsigned long)selectCount] : @"确定";
        self.navigationItem.rightBarButtonItem.title =  doneTititle;
        //[NSString stringWithFormat:@"选择(%lu)", (unsigned long)self.imagePickerController.selectedAssetURLs.count+1];
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:(self.imagePickerController.selectedAssetURLs.count + 1)];
    }
    
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewController:didSelectAsset:)]) {
        [self.delegate assetsCollectionViewController:self didSelectAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    // Validation
    if (self.allowsMultipleSelection) {
       // UIBarButtonItem *t = [self.navigationItem.rightBarButtonItems objectAtIndex:1];
      //  t.title =  [NSString stringWithFormat:@"(%lu)", (unsigned long)self.imagePickerController.selectedAssetURLs.count-1];
        NSUInteger selectCount = self.imagePickerController.selectedAssetURLs.count-1;
        NSString *doneTititle = selectCount ? [NSString stringWithFormat:@"确定(%ld)",(unsigned long)selectCount] : @"确定";
        self.navigationItem.rightBarButtonItem.title =  doneTititle;
        //self.navigationItem.rightBarButtonItem.title =  [NSString stringWithFormat:@"选择(%lu)", (unsigned long)self.imagePickerController.selectedAssetURLs.count-1];
        self.navigationItem.rightBarButtonItem.enabled = [self validateNumberOfSelections:(self.imagePickerController.selectedAssetURLs.count - 1)];
    }
    
    // Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(assetsCollectionViewController:didDeselectAsset:)]) {
        [self.delegate assetsCollectionViewController:self didDeselectAsset:asset];
    }
}

@end
