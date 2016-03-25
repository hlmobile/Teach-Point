//
//  TPRubricQCellHeading.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCell;

// --------------------------------------------------------------------------------------
// TPRubricQCellHeading - return content of table cell for heading question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellHeading : TPRubricQCell {
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion;

@end
