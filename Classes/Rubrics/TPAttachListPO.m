//
//  TPAttachListPO.m
//  teachpoint
//
//  Created by Jinzhe xi on 8/3/13.
//
//

#import "TPAttachListPO.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPData.h"
#import "TPRubrics.h"
#import "TPAttachListVC.h"

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@implementation TPAttachListPO

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(id)initWithViewDelegate:(TPView *)delegate {
    
    if (debugAttachListPO) NSLog(@"TPAttachListPO initWithViewDelegate");
    
    self = [super init];
    
    if (self != nil) {
        
        viewDelegate = delegate;
    
        table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 300, 220) style:UITableViewStylePlain];
		table.delegate = self;
		table.dataSource = self;
        
        toolbar = [[UIToolbar alloc] init];
        toolbar.frame = CGRectMake(0, 221, 300, 40);
        
        UIBarButtonItem *flexibaleSpaceBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        captureButton = [[UIBarButtonItem alloc] initWithTitle:@"Capture New Image/Video" style:UIBarButtonItemStyleDone target:self action:@selector(onCapture)];
        [captureButton setTintColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.5 alpha:1.0]];
        
        [toolbar setItems:[[NSArray alloc] initWithObjects:flexibaleSpaceBarButton, captureButton,flexibaleSpaceBarButton, nil]];
        [toolbar setTintColor:[UIColor colorWithRed:0.07 green:0.1 blue:0.2 alpha:1.0]];
        
    }
    
    return self;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(void) dealloc {
    if (debugAttachListPO) NSLog(@"TPAttachListPO dealloc");
    [self release];
    [super dealloc];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(void)loadView {
    if (debugAttachListPO) NSLog(@"TPAttachListPO loadView");
    [super loadView];
    [self.view addSubview:table];
    [self.view addSubview:toolbar];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    if (debugAttachListPO) NSLog(@"TPAttachListPO viewDidLoad");
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    if (debugAttachListPO) NSLog(@"TPAttachListPO didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) reset {
    if (debugAttachListPO) NSLog(@"TPAttachListPO reset");
    attach_list = viewDelegate.rubricVC.cur_attachlistVC.attach_list;
    [table reloadData];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [attach_list count];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debugAttachListPO) NSLog(@"TPAttachListPO cellForRowAtIndexPath");
    
	TPUserData *userdata = [attach_list objectAtIndex:[indexPath row]];
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%@", viewDelegate.model.appstate.user_id, userdata.userdata_id];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", userdata.name, [viewDelegate.model prettyStringFromDate:userdata.created newline:FALSE]];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        
        if (userdata.type == TP_USERDATA_TYPE_IMAGE ||
            userdata.type == TP_USERDATA_TYPE_VIDEO) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
    } else if ([cell.textLabel.text isEqualToString:userdata.name] == FALSE) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", userdata.name, [viewDelegate.model prettyStringFromDate:userdata.created newline:FALSE]];
    }
    
    return cell;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (debugAttachListPO) NSLog(@"TPAttachListPO didSelectRowAtIndexPath");
    
    TPUserData *userdata = [attach_list objectAtIndex:[indexPath row]];
    
    if (userdata.type == TP_USERDATA_TYPE_IMAGE || userdata.type == TP_USERDATA_TYPE_VIDEO) {
        
        // if there is an selected item, then display the image preview window
        if ([viewDelegate.model tryLock:viewDelegate.model.uiSyncLock]) {
            
            [viewDelegate.rubricVC onAttachListPOItemClicked:userdata];
            
            [viewDelegate.model freeLock:viewDelegate.model.uiSyncLock];
        }
    }
    
    [table deselectRowAtIndexPath:indexPath animated:NO];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
-(void)onCapture {
    if (debugAttachListPO) NSLog(@"TPAttachListPO onCapture");
    [viewDelegate.rubricVC showCameraView];
}
@end
