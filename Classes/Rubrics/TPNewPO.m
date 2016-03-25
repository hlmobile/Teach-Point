#import "TPView.h"
#import "TPModel.h"
#import "TPData.h"
#import "TPNewPO.h"
#import "TPRubrics.h"
#import "TPRubricList.h"

//------------------------------------------------------------------------------------------------
@implementation TPNewPO

//------------------------------------------------------------------------------------------------
- (id) initWithViewDelegate:(TPView *)delegate parent:(id)parent {
	
	self = [ super init ];
	if (self != nil) {
		
		view_delegate = delegate;
        caller = parent;
		
        groupNames = [[NSMutableArray alloc] init];
        groupRubricArrays = [[NSMutableArray alloc] init];
		
        table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 500, 640) style:UITableViewStyleGrouped];
        table.rowHeight = 40.0;
		table.delegate = self;
		table.dataSource = self;
		[table reloadData];
	}
	return self;
}

//------------------------------------------------------------------------------------------------
- (void)loadView {
    [super loadView];
    [self.view addSubview:table];
}

//------------------------------------------------------------------------------------------------
- (void) dealloc {
    [groupNames release];
    [groupRubricArrays release];
	[self release];
    [super dealloc];
}

//------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [groupNames count];
}

//------------------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([groupNames count] > 0) {
        return [groupNames objectAtIndex:section];
    } else {
        return nil;
    }
}

//------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[groupRubricArrays objectAtIndex:section] count];
}

//------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([groupNames count] > 0) {
        TPRubric *rubric = [[groupRubricArrays objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
        NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%@", rubric.rubric_id, rubric.title];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.textLabel.text = rubric.title;
            cell.accessoryType = UITableViewCellAccessoryNone;
            UIFont *font = [UIFont fontWithName:@"Helvetica" size: 16.0];
            cell.textLabel.font = font;
        }
        return cell;
    } else {
        return nil;
    }
}

//------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [(TPRubricListVC *)caller hidenew];
    TPRubric *rubric = [[groupRubricArrays objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [view_delegate newUserData:rubric];
}

//------------------------------------------------------------------------------------------------
- (void) reset {
    [self regroupRubrics];
	[table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:NO];
    [table reloadData];
}

//------------------------------------------------------------------------------------------------
- (void) regroupRubrics {
    
    // Empty existing arrays
    [groupNames removeAllObjects];
    for (NSMutableArray *array in groupRubricArrays) {
        [array removeAllObjects];
    }
    [groupRubricArrays removeAllObjects];
    
    // Get the rubric list and sort by order
    NSMutableArray *rubricList = [NSMutableArray arrayWithArray:view_delegate.model.rubric_list];
    [rubricList sortUsingSelector:@selector(compareOrder:)];
        
    // Create sorted group name array, and array of arrays
    for (TPRubric *rubric in rubricList) {
        NSArray *groupList = [rubric.group componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        for (NSString *rawGroupName in groupList) {
            NSString *group = [rawGroupName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n"]];
            if (![groupNames containsObject:group]) {
                [groupNames addObject:group];
                [groupRubricArrays addObject:[NSMutableArray arrayWithCapacity:0]];
            }
        }
    }
    [groupNames sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // Loop over forms and create indexset
    for (int i = 0; i < [rubricList count]; i++) {
        
        TPRubric *rubric = [rubricList objectAtIndex:i];
        NSArray *groupList = [rubric.group componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        
        for (NSString *rawGroupName in groupList) {
            
            NSString *group = [rawGroupName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n"]];
            int groupIndex = [groupNames indexOfObject:group];
            
            [[groupRubricArrays objectAtIndex:groupIndex] addObject:rubric];
        }
    }
}

@end
