@class TPView;

//------------------------------------------------------------------------------------------------
@interface TPGradePO : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	
	TPView *view_delegate;
    id caller;
	UITableView *table;
	int mingrade, maxgrade;
}

@property (nonatomic, assign) TPView *view_delegate;

- (id) initWithViewDelegate:(TPView *)delegate parent:(id)parent minGrade:(int)minGrade maxGrade:(int)maxGrade;
- (void) reset;

@end

//------------------------------------------------------------------------------------------------
