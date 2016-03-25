//
//  TPRubricQCellRating.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPQuestion;
@class TPRubricQCellAnnotated;

// --------------------------------------------------------------------------------------
// TPRubricQCellRating - return content of table cell for rating question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellRating : TPRubricQCellAnnotated {
	TPRubricQRatingTable *rating;
	UIImageView *compressor;
	UIButton *compressButton;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
@end

