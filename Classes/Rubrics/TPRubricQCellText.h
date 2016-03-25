//
//  TPRubricQCellText.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPQuestion;
@class TPRubricQCell;

// --------------------------------------------------------------------------------------
// TPRubricQCellText - return content of table cell for rubric question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellText : TPRubricQCell <UITextViewDelegate> {
	NSMutableArray *columns;
    UITextView *text;
	BOOL forceClose;
    BOOL isEditing;
}

@property (readwrite) BOOL forceClose;

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
- (void)dismissKeyboard;

@end
