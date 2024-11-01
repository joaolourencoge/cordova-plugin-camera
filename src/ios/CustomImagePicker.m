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

@implementation CustomImagePicker

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize selectedAssets
    self.selectedAssets = [NSMutableArray array];
    
    // Initialize the collection view layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100); // Set the size of each item
    layout.minimumInteritemSpacing = 10; // Set spacing between items
    layout.minimumLineSpacing = 10; // Set spacing between lines

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    
    // Set the data source and delegate
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    // Register a cell class
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    
    // Add the collection view to the view hierarchy
    [self.view addSubview:self.collectionView];
    
    // Load images
    [self loadImages];

    // Add Done button
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    doneButton.backgroundColor = [UIColor blueColor]; // Set a visible color for testing
    doneButton.translatesAutoresizingMaskIntoConstraints = NO; // Disable autoresizing mask translation
    [doneButton addTarget:self action:@selector(returnSelectedImages) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];

    // Set constraints for the button
    [NSLayoutConstraint activateConstraints:@[
        [doneButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [doneButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [doneButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
        [doneButton.heightAnchor constraintEqualToConstant:40]
    ]];
}

- (void)loadImages {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    self.allAssets = [NSMutableArray array];
    for (PHAsset *asset in fetchResult) {
        [self.allAssets addObject:asset];
    }
    
    [self.collectionView reloadData];
}

// Implement UICollectionViewDelegate and UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allAssets.count; // Return the number of images
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    PHAsset *asset = self.allAssets[indexPath.item];
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    [imageManager requestImageForAsset:asset
                          targetSize:CGSizeMake(100, 100) // Set the desired size
                         contentMode:PHImageContentModeAspectFill
                             options:nil
                       resultHandler:^(UIImage *result, NSDictionary *info) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:result];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        cell.backgroundView = imageView; // Set the image view as the cell's background
        
        // Remove any existing badge
        [[cell.contentView viewWithTag:100] removeFromSuperview];
        
        // Check if the asset is selected and update the cell appearance
        if ([self.selectedAssets containsObject:asset]) {
            // Create badge
            UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, 30, 30)]; // Adjust position as needed
            badgeLabel.tag = 100; // Set a tag to identify the badge later
            badgeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.selectedAssets indexOfObject:asset] + 1]; // Display the index + 1
            badgeLabel.textAlignment = NSTextAlignmentCenter;
            badgeLabel.backgroundColor = [UIColor redColor];
            badgeLabel.textColor = [UIColor whiteColor];
            badgeLabel.layer.cornerRadius = 15; // Half of the width/height for a circle
            badgeLabel.layer.masksToBounds = YES;
            badgeLabel.font = [UIFont boldSystemFontOfSize:14];
            
            [cell.contentView addSubview:badgeLabel]; // Add badge to cell
        }
    }];
    
    return cell;
}

- (void)returnSelectedImages {
    NSMutableArray *selectedImages = [NSMutableArray array];
    
    for (PHAsset *asset in self.selectedAssets) {
        PHImageManager *imageManager = [PHImageManager defaultManager];
        [imageManager requestImageForAsset:asset
                          targetSize:PHImageManagerMaximumSize
                         contentMode:PHImageContentModeAspectFill
                                options:nil
                          resultHandler:^(UIImage *result, NSDictionary *info) {
            if (result) {
                [selectedImages addObject:result];
            }
            // Check if all images have been processed
            if (selectedImages.count == self.selectedAssets.count) {
                NSLog(@"Delegate: %@", self.delegate); // Log the delegate
                if ([self.delegate respondsToSelector:@selector(didSelectImages:)]) {
                    [self.delegate didSelectImages:selectedImages]; // Notify the delegate
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.allAssets[indexPath.item];
    
    if ([self.selectedAssets containsObject:asset]) {
        // Deselect the asset
        [self.selectedAssets removeObject:asset];
    } else {
        // Select the asset
        [self.selectedAssets addObject:asset];
    }
    
    // Reload the cell to update its appearance
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end