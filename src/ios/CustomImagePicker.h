#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@protocol CustomImagePickerDelegate <NSObject>
- (void)didSelectImages:(NSArray<UIImage *> *)images;
- (void)didCancelImageSelection;
@end

@interface CustomImagePicker : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) id<CustomImagePickerDelegate> delegate;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedAssets;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *allAssets;

@end
