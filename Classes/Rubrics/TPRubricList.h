@class TPView;
@class TPRubricQRatingTable;
@class TPNewPO;
@class TPUserData;
@class TPMyCameraVC;

#import "TPCamera.h"
#import "TPVideo.h" //jxi;
#import "TPImagePreviewDelegate.h"

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@interface TPRubricListVC : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, TPPreviewDelegate, TPVideoPreviewDelegate> {
    
    TPView *viewDelegate;
    
    UISegmentedControl *viewControl;
    
    UIBarButtonItem *leftNewButton;
    UIBarButtonItem *rightbutton;
	
    TPNewPO *newPO;
	UIPopoverController *newPOC;
    
    id<TPImagePreviewDelegate> imagePreviewVC;
    TPPreviewVC *previewVC;
    TPVideoPreviewVC *videoVC; //jxi;
    NSString *preview_userdataid;
    
    //jxi
    NSMutableArray *formDataArrays; // store form data and non-form data which is not attached to any form or questions
    UILabel *titleLabel;
}

@property (nonatomic, retain) id<TPImagePreviewDelegate> imagePreviewVC;
@property (nonatomic, retain) id<TPVPreviewDelegate> videoPreviewVC; //jxi;
@property (nonatomic, retain) TPPreviewVC *previewVC;
@property (nonatomic, retain) TPVideoPreviewVC *videoVC; //jxi;
@property (nonatomic, retain) NSString *preview_userdataid;

- (id) initWithView:(TPView *)mainview;
- (void) reset;
- (void) resetPrompt;
- (void) switchView;
- (void) setSelectedView:(int)index;
- (void) hidenew;
- (void) resetPreview;
- (void) resetFormDataArray; //jxi; reform the list of userdata to be displayed.
- (void) resetVideoPreview; //jxi;

@end

// --------------------------------------------------------------------------------------
// TPRubricListCell - return content of table cell for rubric question
// --------------------------------------------------------------------------------------
@interface TPRubricListCell : UITableViewCell {
    
    TPView *viewDelegate;
    NSString *userdata_id;
    UILabel *title;
    UILabel *status;
    UILabel *description;
    UILabel *itemtag;
    UILabel *date;
    UIImageView *shared;
    UIImageView *reflection;
    UIImageView *signature;
    UIImageView *thumbnail;
    TPUserdataTypes contentType;
}

@property (nonatomic, retain) NSString *userdata_id;

+ (int) cellHeightForCellWithUserdata:(TPUserData *)aUserdata mainView:(TPView *)mainView;

- (id) initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier userdata:(TPUserData *)userdata;
- (void) updateStatus;
- (void) updateCellGeometryForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void) updateContent;

// getters
- (TPUserdataTypes) getContentType;
- (NSString *) getUserdataID;

@end

// --------------------------------------------------------------------------------------
