#import "TPView.h"
#import "TPModel.h"
#import "TPUtil.h"
#import "TPCamera.h"
#import "TPData.h"
#import "TPDatabase.h"
#import "TPRubricList.h"
#import "TPRoundRect.h"
#import "TPCompat.h"

#import <QuartzCore/QuartzCore.h>

// --------------------------------------------------------------------------------------
// TPPreviewVC - image viewer class
// --------------------------------------------------------------------------------------
@implementation TPPreviewVC

@synthesize previewDelegate;
@synthesize imageDescription;
@synthesize userdata_id;

// --------------------------------------------------------------------------------------
- (id) initWithViewDelegate:(TPView *)delegate
                   userdata:(TPUserData *)someData
                      image:(UIImage *)mainImage
                       name:(NSString *)name
                      share:(BOOL)share
                description:(NSString *)description
                 userdataID:(NSString *)userdataid
                imageOrigin:(int)imageOrigin
                   newImage:(BOOL)isNewImage {
    
    if (debugPreview) NSLog(@"TPPreviewVC initWithViewDelegate");
    self = [super init];
    if (self) {
        
        viewDelegate = delegate;
        self.userdata_id = userdataid;
        newImage = isNewImage;
        
        // image
        if (mainImage != nil) {
            mainImageView = [[UIImageView alloc] initWithImage:mainImage];
        } else {
            mainImageView = [[UIImageView alloc] init];
            imageLoadingIndicator =[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
        [mainImageView setContentMode:UIViewContentModeScaleAspectFit];
        [mainImageView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        
        imageDescription = @"";
        if (description != nil) {
            self.imageDescription = description;
        }
        
        // toolbar
        toolbarVisible = YES;
        //toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 768, 44)];
        toolbar = [[UIToolbar alloc] init];
        [toolbar setBarStyle:UIBarStyleBlack];
        NSMutableArray *toolbarItems = [NSMutableArray array];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 80, 37)];
        nameLabel.text = @"Name";
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        nameLabel.textColor = [UIColor whiteColor];
		nameLabel.textAlignment = TPTextAlignmentRight;
        UIBarButtonItem *namelabeldBButton = [[UIBarButtonItem alloc] initWithCustomView:nameLabel];
        [toolbarItems addObject:namelabeldBButton];
        [nameLabel release];
        [namelabeldBButton release];
        
        nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 7, 200, 30)];
        [nameTextField setBorderStyle:UITextBorderStyleRoundedRect];
        if (name != nil) {
            nameTextField.text = name;
        } else {
            nameTextField.placeholder = @"Image name";
        }
        [nameTextField setClearButtonMode:UITextFieldViewModeNever];
        nameTextField.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        nameTextField.delegate = self;
        UIBarButtonItem *imagenameBButton = [[UIBarButtonItem alloc] initWithCustomView:nameTextField];
        [toolbarItems addObject:imagenameBButton];
        [imagenameBButton release];
        
        UIBarButtonItem *fixedSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        fixedSpace1.width = 20;
        [toolbarItems addObject:fixedSpace1];
        [fixedSpace1 release];
        
        UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 50, 37)];
        shareLabel.text = @"Share";
        shareLabel.textColor = [UIColor whiteColor];
		shareLabel.textAlignment = TPTextAlignmentRight;
        shareLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        shareLabel.backgroundColor = [UIColor clearColor];
		UIBarButtonItem *shareBButton = [[UIBarButtonItem alloc] initWithCustomView:shareLabel];
        [toolbarItems addObject:shareBButton];
        [shareLabel release];
        [shareBButton release];
        
        shareSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 2, 100, 37)];
        [shareSwitch setOn:share animated:NO];
        [shareSwitch addTarget:self action:@selector(saveShare) forControlEvents:UIControlEventValueChanged];
        shareSwitch.enabled = newImage || [viewDelegate.model userOwnsUserdata];
        UIBarButtonItem *switchBButton = [[UIBarButtonItem alloc] initWithCustomView:shareSwitch];
        [toolbarItems addObject:switchBButton];
        [switchBButton release];
        
        UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        fixedSpace2.width = 20;
        [toolbarItems addObject:fixedSpace2];
        [fixedSpace2 release];
        
        UIBarButtonItem *detailsBButton = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStyleBordered target:self action:@selector(showDetailsAction)];
        [toolbarItems addObject:detailsBButton];
        [detailsBButton release];
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        [toolbarItems addObject:flexibleSpace];
        [flexibleSpace release];
        
        if (imageOrigin == TP_IMAGE_ORIGIN_LOCAL) {
            trashBButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashAction)];
            [toolbarItems addObject:trashBButton];
            
            UIBarButtonItem *fixedSpace3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            fixedSpace3.width = 20;
            [toolbarItems addObject:fixedSpace3];
            [fixedSpace3 release];
        }
        
        UIBarButtonItem *doneBButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(doneAction)];
        [toolbarItems addObject:doneBButton];
        [doneBButton release];
        
        [toolbar setItems:toolbarItems animated:YES];
        [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // --------------- Details slider -------------------
        isDetailsViewVisible = NO;
        visibleSliderFrame = CGRectMake(114, 0, 540, 260);
        hiddenSliderFrame  = CGRectMake(114, -260, 540, 260);
        
        // Slider background frame
        detailsSliderView = [[TPRoundRectView alloc] initWithFrame:CGRectMake(0, 0, 500, 300)];
        detailsSliderView.rectColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        detailsSliderView.strokeColor = [UIColor clearColor];
        detailsSliderView.cornerRadius = 15.0;
        detailsSliderView.alpha = 1.0f;
        [detailsSliderView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin)];
        
        // name label
        nameSliderLabel = [[UILabel alloc] init];
        nameSliderLabel.text = @"Name";
        nameSliderLabel.textColor = [UIColor whiteColor];
        nameSliderLabel.backgroundColor = [UIColor clearColor];
        [detailsSliderView addSubview:nameSliderLabel];
        
        // name text field
        nameSliderTextField = [[UITextField alloc] init];
        nameSliderTextField.delegate = self;
        if (name == nil) {
            nameSliderTextField.placeholder = @"Image name";
        } else {
            [nameSliderTextField setText:nameTextField.text];
        }
        [nameSliderTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [nameSliderTextField setClearButtonMode:UITextFieldViewModeNever];
        [detailsSliderView addSubview:nameSliderTextField];
        
        // share control
        shareSliderLabel = [[UILabel alloc] init];
        shareSliderLabel.text = @"Share";
        shareSliderLabel.textAlignment = TPTextAlignmentRight;
        shareSliderLabel.textColor = [UIColor whiteColor];
        shareSliderLabel.backgroundColor = [UIColor clearColor];
        [detailsSliderView addSubview:shareSliderLabel];
        shareSliderSwitch = [[UISwitch alloc] init];
        [shareSliderSwitch setOn:[shareSwitch isOn] animated:NO];
        shareSliderSwitch.enabled = newImage || [viewDelegate.model userOwnsUserdata];
        [detailsSliderView addSubview:shareSliderSwitch];
        
        // description label
        descriptionSliderLabel = [[UILabel alloc] init];
        descriptionSliderLabel.text = @"Description";
        descriptionSliderLabel.textColor = [UIColor whiteColor];
        descriptionSliderLabel.backgroundColor = [UIColor clearColor];
        [detailsSliderView addSubview:descriptionSliderLabel];
        
        // description text view
        descriptionSliderTextView = [[UITextView alloc] init];
        descriptionSliderTextView.text = self.imageDescription;
        descriptionSliderTextView.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        descriptionSliderTextView.delegate = self;
        [detailsSliderView addSubview:descriptionSliderTextView];
        
        // buttons
        doneDescriptionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [doneDescriptionButton setTitle:@"Done" forState:UIControlStateNormal];
        [doneDescriptionButton addTarget:self action:@selector(doneDetailsAction) forControlEvents:UIControlEventTouchUpInside];
        [detailsSliderView addSubview:doneDescriptionButton];
        
        // delete popover
        UIViewController *deleteContentVC = [[UIViewController alloc] init];
        deleteContentVC.view.frame = CGRectMake(0, 0, 280, 44);
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.frame = CGRectMake(0, 0, 280, 44);
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        [gradientLayer setFrame:CGRectMake(deleteButton.bounds.origin.x,
                                           deleteButton.bounds.origin.y,
                                           deleteButton.bounds.size.width,
                                           deleteButton.bounds.size.height-1)];
        UIColor *d = [UIColor colorWithRed:207.0/255.0 green:0.0 blue:0.0 alpha:1.];
        UIColor *c = [UIColor colorWithRed:207.0/255.0 green:0.0 blue:0.0 alpha:1.];
        UIColor *b = [UIColor colorWithRed:224.0/255.0 green:26.0/255.0 blue:26.0/255.0 alpha:1.];
        UIColor *a = [UIColor colorWithRed:234.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.];
        NSArray *colors = [NSArray arrayWithObjects:(id)a.CGColor, (id)b.CGColor, (id)c.CGColor, (id)d.CGColor, nil];
        [gradientLayer setColors:colors];
        [gradientLayer setLocations:[NSArray arrayWithObjects:
                                     [NSNumber numberWithFloat:0.0],
                                     [NSNumber numberWithFloat:0.5],
                                     [NSNumber numberWithFloat:0.5],
                                     [NSNumber numberWithFloat:1.0], nil]];
        CALayer *layer = [deleteButton layer];
        [layer addSublayer:gradientLayer];
        [deleteButton setTitle:@"Delete Photo" forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [UIFont fontWithName: @"Helvetica-Bold" size: 22];
        [deleteButton addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
        [deleteContentVC.view addSubview:deleteButton];
        deletePopoverVC = [[UIPopoverController alloc] initWithContentViewController:deleteContentVC];
        [deletePopoverVC setPopoverContentSize:CGSizeMake(280, 44)];
        [gradientLayer release];
        [deleteContentVC release];
        
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    if (debugPreview) NSLog(@"TPPreviewVC dealloc");
    self.userdata_id = nil;
    [nameTextField release];
    [shareSwitch release];
    [toolbar release];
    [trashBButton release];
    [mainImageView release];
    [imageDescription release];
    
    if (imageLoadingIndicator) {
        [imageLoadingIndicator release];
        imageLoadingIndicator = nil;
    }
    
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)viewDidLoad {
    if (debugPreview) NSLog(@"TPPreviewVC viewDidLoad");
    [self.view addSubview:mainImageView];
    
    // ---- main view ----
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapAction)];
    [mainImageView addGestureRecognizer:tapRecognizer];
    
    if (imageLoadingIndicator) {
        [mainImageView setUserInteractionEnabled:NO];
        [mainImageView setHidden:YES];
        
        [imageLoadingIndicator setFrame:CGRectMake((self.view.bounds.size.width - 44)/2,
                                                   (self.view.bounds.size.height - 44)/2,
                                                   44, 44)];
        [imageLoadingIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin)];
        [self.view addSubview:imageLoadingIndicator];
        [imageLoadingIndicator startAnimating];
        
    } else {
        [mainImageView setUserInteractionEnabled:YES];
    }
    [tapRecognizer release];
    
    [toolbar setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    [self.view addSubview:toolbar];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    // ---- slider view ----
    [detailsSliderView setFrame:hiddenSliderFrame];
    [self.view addSubview:detailsSliderView];
    [detailsSliderView setHidden:YES];
    [nameSliderLabel setFrame:CGRectMake(27, 20, 46, 21)];
    [nameSliderTextField setFrame:CGRectMake(81, 16, 251, 31)];
    [shareSliderLabel setFrame:CGRectMake(375, 21, 46, 21)];
    [shareSliderSwitch setFrame:CGRectMake(429, 18, 79, 27)];
    [descriptionSliderLabel setFrame:CGRectMake(27, 74, 87, 21)];
    [descriptionSliderTextView setFrame:CGRectMake(27, 103, 481, 77)];
    [doneDescriptionButton setFrame:CGRectMake(234, 200, 74, 37)];
    
}

// --------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
    if (debugPreview) NSLog(@"TPPreviewVC viewWillAppear");
    if (!imageLoadingIndicator) {
        [mainImageView setFrame:self.view.bounds];
    }
}

// --------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    if (debugPreview) NSLog(@"TPPreviewVC viewDidAppear");
    [detailsSliderView setHidden:NO];
}

// --------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated {
    if (debugPreview) NSLog(@"TPPreviewVC viewWillDisappear");
    [detailsSliderView setHidden:YES];
}

// --------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (debugRotate) NSLog(@"TPPreviewVC shouldAutorotateToInterfaceOrientation %d", toInterfaceOrientation);
    return YES;
}

// ================================== IBActions =========================================

// --------------------------------------------------------------------------------------
- (void)trashAction {
    if (debugPreview) NSLog(@"TPPreviewVC trashAction");
    [nameTextField resignFirstResponder];
    
    if (![deletePopoverVC isPopoverVisible]) {
        [deletePopoverVC presentPopoverFromBarButtonItem:trashBButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        [deletePopoverVC dismissPopoverAnimated:YES];
    }
}

// --------------------------------------------------------------------------------------
// imageTapAction - respond to tap on image to hide/unhide toolbar
// --------------------------------------------------------------------------------------
- (void)imageTapAction {
    if (debugPreview) NSLog(@"TPPreviewVC imageTapAction");
    
    if (toolbarVisible) {
        visibleToolbarFrame = toolbar.frame;
        invisibleToolbarFrame = CGRectMake(visibleToolbarFrame.origin.x,
                                           visibleToolbarFrame.origin.y - visibleToolbarFrame.size.height,
                                           visibleToolbarFrame.size.width,
                                           visibleToolbarFrame.size.height);
        [UIView animateWithDuration:0.25f animations:^{
            [toolbar setFrame:invisibleToolbarFrame];
        }];
    } else {
        invisibleToolbarFrame = toolbar.frame;
        visibleToolbarFrame = CGRectMake(invisibleToolbarFrame.origin.x,
                                         invisibleToolbarFrame.origin.y + invisibleToolbarFrame.size.height,
                                         invisibleToolbarFrame.size.width,
                                         invisibleToolbarFrame.size.height);
        [UIView animateWithDuration:0.25f animations:^{
            [toolbar setFrame:visibleToolbarFrame];
        }];
    }
    
    toolbarVisible = !toolbarVisible;
}

// --------------------------------------------------------------------------------------
- (void)configureDetailsView {
    if (debugPreview) NSLog(@"TPPreviewVC configureDetailsView");
    if (nameTextField.text) {
        nameSliderTextField.text = nameTextField.text;
    } else {
        nameSliderTextField.placeholder = nameTextField.placeholder;
    }
    descriptionSliderTextView.text = self.imageDescription;
    [shareSliderSwitch setOn:[shareSwitch isOn]];
}

// --------------------------------------------------------------------------------------
- (void)showDetailsAction {
    
    if (debugPreview) NSLog(@"TPPreviewVC showDetailsAction");
    if (!imageLoadingIndicator) {
        
        [self dismissDeletePopoverAnimated:NO];
        [self configureDetailsView];
        [self performSelectorOnMainThread:@selector(imageTapAction) withObject:self waitUntilDone:YES];
        
        if (isDetailsViewVisible) {
            mainImageView.userInteractionEnabled = YES;
            visibleSliderFrame = detailsSliderView.frame;
            hiddenSliderFrame = CGRectMake(visibleSliderFrame.origin.x,
                                           visibleSliderFrame.origin.y - visibleSliderFrame.size.height,
                                           visibleSliderFrame.size.width,
                                           visibleSliderFrame.size.height);
            [UIView animateWithDuration:0.25f animations:^{
                [detailsSliderView setFrame:hiddenSliderFrame];
            }];
        } else {
            mainImageView.userInteractionEnabled = NO;
            hiddenSliderFrame = detailsSliderView.frame;
            visibleSliderFrame = CGRectMake(hiddenSliderFrame.origin.x,
                                            hiddenSliderFrame.origin.y + hiddenSliderFrame.size.height,
                                            hiddenSliderFrame.size.width,
                                            hiddenSliderFrame.size.height);
            [UIView animateWithDuration:0.25f animations:^{
                [detailsSliderView setFrame:visibleSliderFrame];
            }];
        }
        isDetailsViewVisible = !isDetailsViewVisible;
    } else {
        UIAlertView *waitAlert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Operation can't be performed during image loading"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles: nil];
        [waitAlert show];
        [waitAlert release];
    }
}

// --------------------------------------------------------------------------------------
- (void)dismissDeletePopoverAnimated:(BOOL)isAnimated {
    if (debugPreview) NSLog(@"TPPreviewVC dismissDeletePopoverAnimated");
    if ([deletePopoverVC isPopoverVisible]) {
        [deletePopoverVC dismissPopoverAnimated:isAnimated];
    }
}

// --------------------------------------------------------------------------------------
- (void)delete {
    if (debugPreview) NSLog(@"TPPreviewVC delete");
    [self dismissDeletePopoverAnimated:NO];
    [previewDelegate trashPreviewWithDeviceOrientation:[[UIDevice currentDevice] orientation]];
}

// --------------------------------------------------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return [TPUtil shouldChangeTextInRange:range replacementText:string maxLength:128];
}

// --------------------------------------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
    return [TPUtil shouldChangeTextInRange:range replacementText:string maxLength:1024];
}

// --------------------------------------------------------------------------------------
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (debugPreview) NSLog(@"TPPreviewVC textFieldShouldBeginEditing");
    return newImage || [viewDelegate.model userOwnsUserdata]; // Only edit if permitted (owned by user)
}

// --------------------------------------------------------------------------------------
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (debugPreview) NSLog(@"TPPreviewVC textViewShouldBeginEditing");
    return newImage || [viewDelegate.model userOwnsUserdata];  // Only edit if permitted (owned by user)
}

// --------------------------------------------------------------------------------------
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (debugPreview) NSLog(@"TPPreviewVC textFieldDidEndEditing");
    [self save:NO];
}

// --------------------------------------------------------------------------------------
- (void)textViewDidEndEditing:(UITextView *)textView {
    if (debugPreview) NSLog(@"TPPreviewVC textViewDidEndEditing");
    [self save:NO];
}

// --------------------------------------------------------------------------------------
// TPImagesPreviewDelegate methods
- (void) reloadImage:(UIImage *)someimage name:(NSString *)name share:(BOOL)share description:(NSString *)description {
    if (debugPreview) NSLog(@"TPPreviewVC reloadImage");
    // image loading indicator
    [imageLoadingIndicator stopAnimating];
    [imageLoadingIndicator removeFromSuperview];
    [imageLoadingIndicator release];
    imageLoadingIndicator = nil;
    
    // main image
    [mainImageView setImage:someimage];
    [mainImageView setHidden:NO];
    [mainImageView setUserInteractionEnabled:YES];
    [mainImageView setFrame:self.view.bounds];
    
    // reconfigure fields
    nameTextField.text = name;
    nameSliderTextField.text = name;
    [shareSwitch setOn:share];
    [shareSliderSwitch setOn:share];
    descriptionSliderTextView.text = description;
    
    [self.view setNeedsDisplay];
}

// --------------------------------------------------------------------------------------
// doneAction - close preview screen
// --------------------------------------------------------------------------------------
- (void)doneAction {
    if (debugPreview) NSLog(@"TPPreviewVC doneAction");
    if ([nameTextField isFirstResponder]) [nameTextField resignFirstResponder];
    [self dismissDeletePopoverAnimated:NO];
    [self.previewDelegate donePreviewWithDeviceOrientation:[[UIDevice currentDevice] orientation]];
    [self save:NO];
}

// --------------------------------------------------------------------------------------
- (void)doneDetailsAction {
    if (debugPreview) NSLog(@"TPPreviewVC doneDetailsAction");
    if ([nameSliderTextField isFirstResponder]) [nameSliderTextField resignFirstResponder];
    if ([descriptionSliderTextView isFirstResponder]) [descriptionSliderTextView resignFirstResponder];
    nameTextField.text = nameSliderTextField.text;
    [shareSwitch setOn:[shareSliderSwitch isOn]];
    self.imageDescription = descriptionSliderTextView.text;
    [self showDetailsAction];
    [self save:NO];
}

// --------------------------------------------------------------------------------------
- (void) saveShare {
    if (debugPreview) NSLog(@"TPPreviewVC saveShare");
    [self save:NO];
}

// --------------------------------------------------------------------------------------
// Image operations
- (void)save:(BOOL)dismiss {
    
    if (debugPreview) NSLog(@"TPPreviewVC save %d", dismiss);
    if (!newImage && ![viewDelegate.model userOwnsUserdata]) {
        if (debugCamera) NSLog(@"TPPreviewVC save ABORTED");
        return;
    }
    [previewDelegate savePreviewWithDeviceOrientation:[[UIDevice currentDevice] orientation]
                                            imageName:nameTextField.text
                                                share:[shareSwitch isOn] ? 1 : 0
                                          description:descriptionSliderTextView.text
                                              dismiss:dismiss];
}


@end
