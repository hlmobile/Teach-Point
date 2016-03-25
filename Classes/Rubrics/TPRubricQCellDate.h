//
//  TPRubricQCellDate.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCellAnnotated;

// --------------------------------------------------------------------------------------
// TPRubricQCellDateBase - base class for date/time/datetime question types
// --------------------------------------------------------------------------------------
@interface TPRubricQCellDateBase: TPRubricQCellAnnotated <UITextFieldDelegate> {
    UITextField *dateTextField;
    NSDate *date;
    NSDateFormatter *dateFormatter;
    NSLock *dateformatterLock;
    UIDatePicker *datePicker;
    UIPopoverController *datePopoverController;
}

@property (nonatomic, retain) NSDate *date;

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
- (void)setDateFormat;

@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellDate : TPRubricQCellDateBase
@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellTime : TPRubricQCellDateBase
@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellDateTime : TPRubricQCellDateBase
@end
