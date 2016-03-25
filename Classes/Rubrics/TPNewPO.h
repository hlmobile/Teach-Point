@class TPView;

//------------------------------------------------------------------------------------------------
@interface TPNewPO : UIViewController <UITableViewDelegate, UITableViewDataSource> {

	TPView *view_delegate;
    id caller;
	UITableView *table;
    NSMutableArray *groupNames;
    NSMutableArray *groupRubricArrays;
}

- (id) initWithViewDelegate:(TPView *)delegate parent:(id)parent;
- (void) reset;

@end

//------------------------------------------------------------------------------------------------
