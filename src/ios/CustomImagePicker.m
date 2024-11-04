#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <Cordova/CDV.h>

@protocol CustomImagePickerDelegate <NSObject>
- (void)didSelectImages:(NSArray<UIImage *> *)images;
- (void)didCancelImageSelection;
@end

@interface CustomImagePicker : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) id<CustomImagePickerDelegate> delegate;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *selectedAssets;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *allAssets;
@property (nonatomic, strong) NSString *callbackId;

@end

@implementation CustomImagePicker

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize selectedAssets
    self.selectedAssets = [NSMutableArray array];
    
    // Create a header view
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    headerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7]; // Set background color with transparency

    // Add title label to header
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, headerView.bounds.size.width, 60)];
    titleLabel.text = @"";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:titleLabel];

    // Add Cancel button
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelImageSelection) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO; // Disable autoresizing mask translation
    [headerView addSubview:cancelButton];

    // Add Done button
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(returnSelectedImages) forControlEvents:UIControlEventTouchUpInside];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO; // Disable autoresizing mask translation
    [headerView addSubview:doneButton];

    // Set button styles to match
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    doneButton.backgroundColor = [UIColor clearColor]; // Match Cancel button style

    // Set constraints for the buttons
    [NSLayoutConstraint activateConstraints:@[
        [cancelButton.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:20],
        [cancelButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        
        [doneButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-20],
        [doneButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor]
    ]];

    // Add the header view to the main view
    [self.view addSubview:headerView];

    // Initialize the collection view layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(130, 130); // Increased size to reduce black space
    layout.minimumInteritemSpacing = 0; // Adjust spacing between items
    layout.minimumLineSpacing = 0; // Adjust spacing between lines

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(headerView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(headerView.frame)) collectionViewLayout:layout];
    
    // Set the data source and delegate
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    // Register a cell class
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    
    // Add the collection view to the view hierarchy
    [self.view addSubview:self.collectionView];
    
    // Load images
    [self loadImages];
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
        
        // Remove existing badge if any
        UILabel *existingBadge = [cell.contentView viewWithTag:100];
        if (existingBadge) {
            [existingBadge removeFromSuperview];
        }

        // Add badge if the asset is selected
        if ([self.selectedAssets containsObject:asset]) {
            UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.bounds.size.width - 40, cell.bounds.size.height - 40, 30, 30)]; // Bottom-right position
            badgeLabel.tag = 100; // Set a tag to identify the badge later
            badgeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.selectedAssets indexOfObject:asset] + 1]; // Display the index + 1
            badgeLabel.textAlignment = NSTextAlignmentCenter;
            badgeLabel.backgroundColor = [UIColor colorWithRed:179/255.0 green:0/255.0 blue:27/255.0 alpha:1.0]; // Changed to #B3001B
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
    NSMutableArray<NSString *> *originalPaths = [NSMutableArray array]; // Array to hold original paths
    
    for (PHAsset *asset in self.selectedAssets) {
        PHImageManager *imageManager = [PHImageManager defaultManager];
        
        // Request the original image data and metadata
        [imageManager requestImageDataForAsset:asset
                                  options:nil
                            resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (imageData) {
                // Create a UIImage from the original data
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    // Adjust the image orientation
                    image = [self fixOrientation:image withOrientation:orientation];
                    [selectedImages addObject:image];
                }
                
                // Create a unique file name for the original image
                NSString *fileName = [NSString stringWithFormat:@"image_%@.%@", [[NSUUID UUID] UUIDString], [dataUTI pathExtension]];
                NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                
                // Save the original image data directly to file
                NSError *error = nil;
                if ([imageData writeToFile:filePath options:NSAtomicWrite error:&error]) {
                    [originalPaths addObject:filePath]; // Add the file path to the array
                } else {
                    NSLog(@"Failed to save image to path: %@, error: %@", filePath, error.localizedDescription);
                }
            }
            
            // Check if all images have been processed
            if (selectedImages.count == self.selectedAssets.count) {
                NSLog(@"Delegate: %@", self.delegate); // Log the delegate
                
                // Call the delegate method with both images and their original paths
                [self.delegate didSelectImages:selectedImages ];
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
}

// Method to fix the orientation of the image
- (UIImage *)fixOrientation:(UIImage *)image withOrientation:(UIImageOrientation)orientation {
    if (orientation == UIImageOrientationUp) return image; // No need to fix

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return normalizedImage;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.allAssets[indexPath.item];
    
    if ([self.selectedAssets containsObject:asset]) {
        // Deselect the asset
        NSInteger unselectedIndex = [self.selectedAssets indexOfObject:asset];
        [self.selectedAssets removeObject:asset];
        
        // Update badge labels for remaining selected assets
        [self updateBadgeLabelsAfterUnselectionAtIndex:unselectedIndex];
    } else {
        // Select the asset
        [self.selectedAssets addObject:asset];
    }
    
    // Reload the cell to update its appearance
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

// Method to update badge labels after an image is unselected
- (void)updateBadgeLabelsAfterUnselectionAtIndex:(NSInteger)unselectedIndex {
    for (NSInteger i = unselectedIndex; i < self.selectedAssets.count; i++) {
        PHAsset *asset = self.selectedAssets[i];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.allAssets indexOfObject:asset] inSection:0]];
        
        if (cell) {
            UILabel *badgeLabel = [cell.contentView viewWithTag:100]; // Assuming tag 100 is used for the badge
            if (badgeLabel) {
                badgeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)(i + 1)]; // Update badge text
            }
        }
    }
}

// Method to handle cancel action
- (void)cancelImageSelection {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
