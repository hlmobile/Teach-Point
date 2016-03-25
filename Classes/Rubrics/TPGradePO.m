#import "TPView.h"
#import "TPModel.h"
#import "TPData.h"
#import "TPGradePO.h"
#import "TPRubrics.h"
#import "TPRubricList.h"
#import "TPCompat.h"

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
@implementation TPGradePO

@synthesize view_delegate;

- (id) initWithViewDelegate:(TPView *)delegate parent:(id)parent minGrade:(int)minGrade maxGrade:(int)maxGrade {
	
	self = [super init];
	if (self != nil) {
		
		view_delegate = delegate;
        caller = parent;
		mingrade = minGrade;
		maxgrade = maxGrade;
		
        table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 180, 400) style:UITableViewStylePlain];
		table.delegate = self;
		table.dataSource = self;
		[table reloadData];
	}
	return self;
}

- (void)loadView {
    [super loadView];
    [self.view addSubview:table];
}

- (void) dealloc {
	[self release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[view_delegate.model getCurrentTarget] getGradeRangeSize];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d", indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.text = [[view_delegate.model getCurrentTarget] getGradePickerStringByIndex:indexPath.row];
        cell.textLabel.textAlignment = TPTextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;
		UIFont *font = [UIFont fontWithName: @"Helvetica" size: 20.0];
		cell.textLabel.font = font;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[(TPRubricQCellSubHeading *)caller changeGradeActionCallback:[NSNumber numberWithInt:[[view_delegate.model getCurrentTarget] getGradeIdByPickerIndex:indexPath.row]]];
}

//------------------------------------------------------------------------------------------------
- (void) reset {
	[table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:NO];
    [table reloadData];
}


@end

//------------------------------------------------------------------------------------------------
