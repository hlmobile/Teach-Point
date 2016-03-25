//
//  TPRubricQCellUnknown.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCell;

// --------------------------------------------------------------------------------------
// TPRubricQCellUnknown - return content of tabele cell for question of unknown type
// --------------------------------------------------------------------------------------
@interface TPRubricQCellUnknown : TPRubricQCell {
    UILabel *needUpdateLabel;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;

@end
