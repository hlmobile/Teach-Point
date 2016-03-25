//
//  TPRubricQCellMultiSelect.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPQuestion;
@class TPRubricQCellAnnotated;

// --------------------------------------------------------------------------------------
// TPRubricQCellMultiSelect - return content of table cell for uni-/multiselect question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellMultiSelect : TPRubricQCellAnnotated {
	TPRubricQMultiSelectTable *multiSelect;
	UILabel *noAnswers;
	UIImageView *compressor;
	UIButton *compressButton;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
@end

