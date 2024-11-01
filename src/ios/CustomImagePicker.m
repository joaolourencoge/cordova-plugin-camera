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
        [self.selectedAssets removeObject:asset];
    } else {
        // Select the asset
        [self.selectedAssets addObject:asset];
    }
    
    // Reload the cell to update its appearance
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end
