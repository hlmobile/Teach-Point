//
//  TPAttachListVC.m
//  teachpoint
//
//  Created by Jinzhe xi on 8/2/13.
//
//

#import "TPAttachListVC.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPData.h"
#import "TPRubrics.h"
#import "TPRubricQCellText.h"
#import "TPRubricQCellSignature.h"
#import "TPRubricQCellInstructions.h"

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@implementation TPAttachListVC

@synthesize attachListHeight;
@synthesize attach_list;
@synthesize aud_id;
@synthesize aq_id;

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(id)initWithViewDelegate:(TPView *)delegate parent:(id)parent containerType:(int)containerType  parentFormUserDataID:(NSString *)audId parentQuestionID:(int)aqId {
    
    if (debugAttachListVC) NSLog(@"TPAttachListVC initWithViewDelegate");
    
    self = [super init];
    if (self != nil) {
        
        viewDelegate = delegate;
        
        container = parent;
        
        self.title = @"";
        
        container_type = containerType;
        
        aud_id = audId;
        
        aq_id = aqId;
        
        attach_list = [[NSMutableArray alloc] init];
        
        [self reset];
    }
    return self;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    if (debugAttachListVC) NSLog(@"TPAttachListVC viewDidLoad");
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    if (debugAttachListVC) NSLog(@"TPAttachListVC didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(void)reset {
    if (debugAttachListVC) NSLog(@"TPAttachListVC reset");
    [self regroupNonFormData];
    [self reloadData];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) regroupNonFormData {
    
    if (debugAttachListVC) NSLog(@"TPAttachListVC regroupNonFormData");
    
    // Empty existing arrays
    [attach_list removeAllObjects];
    
    // Get the non-form data list
    NSMutableArray *userdataList = [NSMutableArray arrayWithArray:viewDelegate.model.userdata_list];
    
    // Loop over userdata list and a list of non-form data to be attached
    for (int i = 0; i < [userdataList count]; i++) {
        
        TPUserData *userdata = [userdataList objectAtIndex:i];
        
        if (container_type == TP_ATTACHLIST_CONTAINER_TYPE_FORM) {
            if ([userdata.aud_id isEqualToString:aud_id] && userdata.aq_id < 1) {
                [attach_list addObject:userdata];
            }
        } else if (container_type == TP_ATTACHLIST_CONTAINER_TYPE_QUESTION) {
            if ([userdata.aud_id isEqualToString:aud_id] && userdata.aq_id==aq_id) {
                [attach_list addObject:userdata];
            }
        }
    }
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) reloadData {
    
    if (debugAttachListVC) NSLog(@"TPAttachListVC reloadData");
    
    if (backgroundView != nil) {
        [backgroundView removeFromSuperview];
        [backgroundView release];
    }
    
    backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 680)] autorelease];
    
    float item_height = 12.0;
    float offset_bottom_margin = 5.0;
    float x1 = 80.0;
    float y1 = 0.0;
    
    // Add title label Attachments:
    CGRect frame = CGRectMake(0, 0, 100, item_height);
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:12.0];
    label.textAlignment = UITextAlignmentLeft;
    label.textColor = [UIColor blackColor];
    label.text = @"Attachments:";
    
    [backgroundView addSubview:label];
    
    // Add labels for each attachment
    for(TPUserData *userdata in attach_list) {
        frame = CGRectMake(x1, y1, 280, item_height);
        label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textAlignment = UITextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.text = [NSString stringWithFormat:@"%@ (%@)", userdata.name, [viewDelegate.model prettyStringFromDate:userdata.created newline:FALSE]];
        [backgroundView addSubview:label];
        y1 += item_height + offset_bottom_margin;
    }
    
    attachListHeight = y1;
    if (attachListHeight == 0.0)
        attachListHeight = item_height;
    
    backgroundView.frame = CGRectMake(0, 0, 320, attachListHeight);
    
    [self.view addSubview:backgroundView];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) updateUI {
    if (debugAttachListVC) NSLog(@"TPAttachListVC updateUI");
    
    if (container_type == TP_ATTACHLIST_CONTAINER_TYPE_QUESTION) {
        
        [container updateUI];
        if([container isKindOfClass:[TPRubricQCellText class]] ||
           [container isKindOfClass:[TPRubricQCellSignature class]] ||
           [container isKindOfClass:[TPRubricQCellInstructions class]]) {
            
            [container reloadCellAction];
        } else {
            
            [container updateModified];
        }
    }
}

@end
