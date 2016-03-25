//
//  TPRubricQCellMultiSelectCumulative.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCellAnnotated;

// --------------------------------------------------------------------------------------
// TPRubricQCellMultiSelectCumulative - return content of table cell for cumulative multiselect question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellMultiSelectCumulative : TPRubricQCellAnnotated {
	TPRubricQMultiSelectCumulativeTable *multiSelect;
	UILabel *noAnswers;
	UIImageView *compressor;
	UIButton *compressButton;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;

@end
