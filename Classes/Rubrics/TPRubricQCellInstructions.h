//
//  TPRubricQCellInstructions.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCell;

// --------------------------------------------------------------------------------------
// TPRubricQCellInstructions - return content of table cell for instructions question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellInstructions : TPRubricQCell {
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;

@end
