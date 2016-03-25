//
//  TPRubricQCellDate.m
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

#import <QuartzCore/QuartzCore.h>
#import "TPData.h"
#import "TPView.h"
#import "TPStyle.h"
#import "TPModel.h"
#import "TPRubrics.h"
#import "TPRubricQCellDate.h"
#import "TPUtil.h"
#import "TPCompat.h"

// --------------------------------------------------------------------------------------
// TPRubricQCellDateBase - base class for date/time/datetime question types
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellDateBase

@synthesize date;

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview
              style:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
           question:(TPQuestion *)somequestion
             isLast:(BOOL)isLast {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        canEdit = [viewDelegate.model userCanEditQuestion:question];
        annotEditable = NO;
        
        // configuration of cell
        BOOL isCellEditable = YES;
        BOOL isRubricEditable = [viewDelegate.model isRubricEditable:question.rubric_id];
        BOOL isQuestionEditable = [question isQuestionEditable];
        if ( !isQuestionEditable || !isRubricEditable) {
            isCellEditable = NO;
        }
        
        [self.contentView setStyle:[TPStyle styleWithDictionary:question.style]];
        
        // Create date picker
        UIViewController* popoverContent = [[UIViewController alloc] init];
        UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 325, 215)];
        popoverView.backgroundColor = [UIColor whiteColor];
        datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 325, 300)];
        [datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
        [popoverView addSubview:datePicker];
        popoverContent.view = popoverView;
        popoverContent.contentSizeForViewInPopover = CGSizeMake(325, 215);
        datePopoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
        [popoverView release];
        [popoverContent release];
        dateFormatter = [[NSDateFormatter alloc] init];
        dateformatterLock = [[NSLock alloc] init];
        [self setDateFormat];
        NSDate *datevalue = [viewDelegate.model questionDatevalue:question];
        date = [[NSDate alloc] init];
        self.date = datevalue;
        
        // Create title
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - TP_QUESTION_DATE_TEXTFIELD_WIDTH - 10, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		title = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                          TP_QUESTION_BEFORE_QUESTION_MARGIN,
                                                          textSize.width,//TP_QUESTION_CELL_WIDTH_EFFECTIVE - TP_QUESTION_DATE_TEXTFIELD_WIDTH - 10,
                                                          textSize.height)];
		title.text = question.title;
        title.textColor = [TPRubricQCell getTextColor:canEdit];
		title.numberOfLines = 0;
		title.lineBreakMode = TPLineBreakByWordWrapping;
        title.backgroundColor = [UIColor clearColor];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
        [self.contentView addSubview:title];
        
        // Create date text field
        dateTextField = [[UITextField alloc] initWithFrame:CGRectMake(title.frame.origin.x + title.frame.size.width + 10,
                                                                      TP_QUESTION_BEFORE_QUESTION_MARGIN_DATE,
                                                                      TP_QUESTION_DATE_TEXTFIELD_WIDTH,
                                                                      TP_QUESTION_DATE_TEXTFIELD_HEIGHT)];
        dateTextField.text = self.date ? [self stringFromDate:self.date] : @"";
        dateTextField.textColor = [TPRubricQCell getTextColor:canEdit];
        dateTextField.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        dateTextField.borderStyle = UITextBorderStyleBezel;
        dateTextField.backgroundColor = [UIColor clearColor];
        [dateTextField setClearButtonMode:UITextFieldViewModeAlways];
        [dateTextField setDelegate:self];
        [self.contentView addSubview:dateTextField];
        
        // Find Y position of next element
        float elementBaseY;
        if ((dateTextField.frame.origin.y + dateTextField.frame.size.height) > (title.frame.origin.y + title.frame.size.height)) {
            elementBaseY = dateTextField.frame.origin.y + dateTextField.frame.size.height;
        } else {
            elementBaseY = title.frame.origin.y + title.frame.size.height;
        }
        
        // Create prompt text
        if (![question.prompt isEqualToString:@""]) {
            constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
            textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                   constrainedToSize:constSize
                                       lineBreakMode:TPLineBreakByWordWrapping];
            prompt = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                               title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN, //elementBaseY + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                               textSize.height)];
            prompt.text = question.prompt;
            prompt.textColor = [TPRubricQCell getTextColor:canEdit];
            prompt.numberOfLines = 0;
            prompt.lineBreakMode = TPLineBreakByWordWrapping;
            prompt.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            prompt.textAlignment = TPTextAlignmentLeft;
            prompt.userInteractionEnabled = NO;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
            elementBaseY = prompt.frame.origin.y + prompt.frame.size.height;
        }
        
        // annotation
        CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                     constrainedToSize:constSize
                                                                         lineBreakMode:TPLineBreakByWordWrapping];
        annotText = [[UITextView alloc] initWithFrame:CGRectMake(10, elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
        annotText.text = [viewDelegate.model questionAnnot:question];
        annotText.editable = [viewDelegate.model userCanEditQuestion:question];
        annotText.layer.borderWidth = 1;
        annotText.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        annotText.font = [UIFont fontWithName:@"Helvetica" size:15.0];
        annotText.userInteractionEnabled = YES;
        annotText.delegate = self;
        showAnnotation = (question.annotation && ([annotText.text length] != 0));
        [annotText setHidden:!showAnnotation];
        if (!isCellEditable) [annotText setUserInteractionEnabled:NO];
        [self.contentView addSubview:annotText];
        
        // annotation button
        if (question.annotation) {
            annotButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [annotButton setFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 160, elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
            [annotButton addTarget:self action:@selector(toggleAnnotAction:) forControlEvents:UIControlEventTouchUpInside];
            [annotButton setTitle:@"Annotate" forState:UIControlStateNormal];
            [self.contentView addSubview:annotButton];
        }
        
        // Create "next" button
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
        }
        
        if (nextButton) {
            cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        } else {
            cellHeight = elementBaseY + TP_QUESTION_AFTER_QUESTION_MARGIN;
        }
        
    }
    
    [self updateUI];
    
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [title release];
    [date release];
    [dateTextField release];
    [datePicker release];
    [datePopoverController release];
    [dateFormatter release];
    [dateformatterLock release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    
    // title
    CGSize constSize = CGSizeMake(aCellWidth - TP_QUESTION_DATE_TEXTFIELD_WIDTH - 10, 1000);
    CGSize textSize = [question.title sizeWithFont:title.font
                                 constrainedToSize:constSize
                                     lineBreakMode:TPLineBreakByWordWrapping];
    [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, textSize.width, textSize.height)];
    
    // date text field on the same place
    [dateTextField setFrame:CGRectMake(title.frame.origin.x + title.frame.size.width + 10,
                                       TP_QUESTION_BEFORE_QUESTION_MARGIN_DATE,
                                       TP_QUESTION_DATE_TEXTFIELD_WIDTH,
                                       TP_QUESTION_DATE_TEXTFIELD_HEIGHT)];
    
    // Find Y position of next element
    float elementBaseY;
    if ((dateTextField.frame.origin.y + dateTextField.frame.size.height) > (title.frame.origin.y + title.frame.size.height)) {
        elementBaseY = dateTextField.frame.origin.y + dateTextField.frame.size.height;
    } else {
        elementBaseY = title.frame.origin.y + title.frame.size.height;
    }
    
    if (prompt) {
        constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
        CGSize promptSize = [question.prompt sizeWithFont:prompt.font
                                        constrainedToSize:constSize
                                            lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    elementBaseY + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                    aCellWidth,
                                    promptSize.height)];
        elementBaseY = prompt.frame.origin.y + prompt.frame.size.height;
    }
    
    // annotation text
    if (question.annotation) {
        if (showAnnotation) {
            CGSize constSize = CGSizeMake(aCellWidth, 1000);
            CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                         constrainedToSize:constSize
                                                                             lineBreakMode:TPLineBreakByWordWrapping];
            if (annotEditable) {
                [annotText setFrame:CGRectMake(10,
                                               elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED)];
            }
            else {
                [annotText setFrame:CGRectMake(10,
                                               elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
            }
            elementBaseY = annotText.frame.origin.y + annotText.frame.size.height;
        }
        [annotText setHidden:!showAnnotation];
    }
    
    // annotation button
    if (annotButton) {
        [annotButton setFrame:CGRectMake(aCellWidth - 160, elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
        [annotButton setHidden:showAnnotation];
	}
    
    if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, elementBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
        cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    } else {
        cellHeight = elementBaseY + TP_QUESTION_AFTER_QUESTION_MARGIN;
    }
}

// --------------------------------------------------------------------------------------
- (void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
    if ([datePopoverController isPopoverVisible]) {
        [datePopoverController dismissPopoverAnimated:NO];
    }
}

// --------------------------------------------------------------------------------------
- (void) showDatePicker {
    if (debugRubric) NSLog(@"TPRubricQCellDateBase showDatePicker");
    [datePopoverController presentPopoverFromRect:dateTextField.frame
                                           inView:self
                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                         animated:YES];
}

// --------------------------------------------------------------------------------------
- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    if (!canEdit) return NO;
    if (self.date) {
        [datePicker setDate:self.date animated:NO];
    }
    [self showDatePicker];
    return NO;
}

// --------------------------------------------------------------------------------------
- (BOOL) textFieldShouldClear:(UITextField *)textField {
    [viewDelegate.model updateUserDataDatevalue:question dateValue:nil];
    return YES;
}

// --------------------------------------------------------------------------------------
- (void) dateChanged {
    self.date = datePicker.date;
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    dateTextField.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:self.date]];
    [viewDelegate.model freeLock:dateformatterLock];
    [viewDelegate.model updateUserDataDatevalue:question dateValue:self.date];
}

// --------------------------------------------------------------------------------------
- (void) setDateFormat {
    // defult method. Can be redefined in inherited classes
    datePicker.datePickerMode = UIDatePickerModeDate;
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    [viewDelegate.model freeLock:dateformatterLock];
}

// --------------------------------------------------------------------------------------
- (NSString *) stringFromDate:(NSDate *)someDate {
    if (someDate == nil) return @"";
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
	NSString *date_str = [NSString stringWithFormat:@"%s", [[dateFormatter stringFromDate:someDate] UTF8String]];
	[viewDelegate.model freeLock:dateformatterLock];
	return date_str;
}

@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellDate

- (void) setDateFormat {
    datePicker.datePickerMode = UIDatePickerModeDate;
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    [viewDelegate.model freeLock:dateformatterLock];
}

@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellTime

- (void) setDateFormat {
    datePicker.datePickerMode = UIDatePickerModeTime;
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    [dateFormatter setDateFormat:@"h:mm a"];
    [viewDelegate.model freeLock:dateformatterLock];
}

@end

// --------------------------------------------------------------------------------------
// TPRubricQCellDate - return content of tabele cell for date question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellDateTime

- (void) setDateFormat {
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [viewDelegate.model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    [dateFormatter setDateFormat:@"MM/dd/yyyy h:mm a"];
    [viewDelegate.model freeLock:dateformatterLock];
}

@end
