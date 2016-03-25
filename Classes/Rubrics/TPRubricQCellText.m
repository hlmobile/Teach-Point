//
//  TPRubricQCellText.m
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
#import "TPModelReport.h"
#import "TPRubrics.h"
#import "TPRubricQCellText.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPAttachListVC.h" //jxi;

// --------------------------------------------------------------------------------------
// TPRubricQCellText - return content of table cell for rubric question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellText

@synthesize forceClose;

- (id) initWithView:(TPView *)mainview
              style:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
           question:(TPQuestion *)somequestion
             isLast:(BOOL)isLast {
    
    if (debugRubric) NSLog(@"TPRubricQCellText initWithView");
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        canEdit = [viewDelegate.model userCanEditQuestion:question];
		forceClose = NO;
        isEditing = NO;
        
        // configuration of cell
        BOOL isCellEditable = YES;
        BOOL isRubricEditable = [viewDelegate.model isRubricEditable:question.rubric_id];
        BOOL isQuestionEditable = [question isQuestionEditable];
        if ( !isQuestionEditable || !isRubricEditable) {
            isCellEditable = NO;
        }
        
        // Set cell properties
		self.accessoryType = UITableViewCellAccessoryNone;
        self.contentView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 300);
        
        [self.contentView setStyle:[TPStyle styleWithDictionary:question.style]];
		
		// Create title
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		
		
		title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
		title.text = question.title;
        title.textColor = [TPRubricQCell getTextColor:canEdit];
		title.numberOfLines = 0;
		title.lineBreakMode = TPLineBreakByWordWrapping;
        title.backgroundColor = [UIColor clearColor];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
        [self.contentView addSubview:title];
		
        // Create prompt text
        if (![question.prompt isEqualToString:@""]) {
            textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                   constrainedToSize:constSize
                                       lineBreakMode:TPLineBreakByWordWrapping];
            prompt = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                               title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                               textSize.height)];
            prompt.text = question.prompt;
            prompt.textColor = [TPRubricQCell getTextColor:canEdit];
            prompt.numberOfLines = 0;
            prompt.lineBreakMode = TPLineBreakByWordWrapping;
            prompt.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            //prompt.textAlignment = UITextAlignmentLeft;
            prompt.userInteractionEnabled = NO;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
        }
		
        // If text question then add text area
		CGSize newTextSize = [[viewDelegate.model questionText:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
																	constrainedToSize:constSize
																		lineBreakMode:TPLineBreakByWordWrapping];
		if (prompt) {
            text = [[UITextView alloc] initWithFrame:CGRectMake(10,
                                                                prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                                                TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                                (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
        } else {
            text = [[UITextView alloc] initWithFrame:CGRectMake(10,
                                                                title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                                                TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                                (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
        }
        text.text = [viewDelegate.model questionText:question];
        text.editable = [viewDelegate.model userCanEditQuestion:question];
	    text.layer.borderWidth = 1;
        text.layer.borderColor = [[UIColor lightGrayColor] CGColor];
		text.font = [UIFont fontWithName:@"Helvetica" size:15.0];
		text.userInteractionEnabled = YES;
        text.delegate = self;
        text.autocorrectionType = UITextAutocorrectionTypeYes;
        [self.contentView addSubview:text];
        if (!isCellEditable) text.userInteractionEnabled = NO;
        cellHeight = text.frame.origin.y + text.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
        float attachistButtonX = TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20; //jxi;
		
		// Add scroll button if not the last question
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, text.frame.origin.y + text.frame.size.height + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
            //cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
            
            attachistButtonX = TP_QUESTION_CELL_WIDTH_EFFECTIVE - 65; //jxi;
        }
        
        //jxi; Add attchlist button
        attachlistButton = [[UIButton alloc] initWithFrame:CGRectMake(attachistButtonX, text.frame.origin.y + text.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN, 30, 30)];
        attachlistImage = [UIImage imageNamed:@"paperclip.png"];
        [attachlistButton setImage:attachlistImage forState:UIControlStateNormal];
        [attachlistButton addTarget:self action:@selector(showAttachListPO) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:attachlistButton];
        
        //jxi; Add attachment list
        attachListVC = [[TPAttachListVC alloc]initWithViewDelegate:viewDelegate
                                                            parent:self
                                                     containerType:TP_ATTACHLIST_CONTAINER_TYPE_QUESTION
                                                    parentFormUserDataID:viewDelegate.model.appstate.userdata_id parentQuestionID:question.question_id];
        attachListVC.view.frame = CGRectMake(10, text.frame.origin.y + text.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN, 320, attachListVC.attachListHeight);
        [self.contentView addSubview:attachListVC.view];
        
        [self updateUI];
    }
    return self;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (void) dealloc {
    if (debugRubric) NSLog(@"TPRubricQCellText dealloc");
    [title release];
    if (prompt) {
        [prompt release];
        prompt = NULL;
	}
    [text release];
	if (nextButton) {
		[nextButton release];
		nextButton = 0;
	}
    
    //jxi; Attachment Handling
    if (attachlistButton) {
        [attachlistButton release];
        attachlistButton = 0;
    }
    
    [super dealloc];
}

// --------------------------------------------------------------------------------------
// updateUI - update size of question UI elements
// --------------------------------------------------------------------------------------
-(void) updateUI {
    if (debugRubric) NSLog(@"TPRubricQCellText updateUI %d", [TPUtil isPortraitOrientation]);
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

// --------------------------------------------------------------------------------------
// recalculateCellGeometryForCellWidth - resize UI elements (prompt, textarea, buttons)
// based on specified width of area available
// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    
    if (debugRubric) NSLog(@"TPRubricQCellText recalculateCellGeometryForCellWidth");
    
    // Update prompt if it exists
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    if (prompt) {
        CGSize textSize = [question.prompt sizeWithFont:prompt.font
                                      constrainedToSize:constSize
                                          lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                    aCellWidth,
                                    textSize.height)];
    }
    
    // Update text view
    CGSize newTextSize = [[viewDelegate.model questionText:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                constrainedToSize:constSize
                                                                    lineBreakMode:TPLineBreakByWordWrapping];
    int minHeight = isEditing ? TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT;
    if (prompt) {
        [text setFrame:CGRectMake(10,
                                  prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                  aCellWidth,
                                  (newTextSize.height + 20) > minHeight ? (newTextSize.height + 20) : minHeight)];
    } else {
        [text setFrame:CGRectMake(10,
                                  title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                  aCellWidth,
                                  (newTextSize.height + 20) > minHeight ? (newTextSize.height + 20) : minHeight)];
    }
    
    float attachistButtonX = aCellWidth - 20; //jxi;
    
    // Update next button
    if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, text.frame.origin.y + text.frame.size.height + 10, 30, 30)];
        
        attachistButtonX = aCellWidth - 65; //jxi;
    } 
    
    // jxi;
    attachlistButton.frame = CGRectMake(attachistButtonX, text.frame.origin.y + text.frame.size.height + 10, 30, 30);
    attachListVC.view.frame = CGRectMake(10, text.frame.origin.y + text.frame.size.height + 10, attachListVC.view.frame.size.width, attachListVC.attachListHeight);
    
    if (attachListVC.attachListHeight > attachlistButton.frame.size.height)
        cellHeight = attachListVC.view.frame.origin.y + attachListVC.attachListHeight + TP_QUESTION_AFTER_QUESTION_MARGIN;
    else
        cellHeight = attachlistButton.frame.origin.y + attachlistButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
}

// --------------------------------------------------------------------------------------
// dismissKeyboard - dismiss keyboard if this cell is the first responder
// --------------------------------------------------------------------------------------
- (void)dismissKeyboard {
    if (debugRubric) NSLog(@"TPRubricQCellText dismissKeyboard");
    if ([text isFirstResponder]) {
        if (debugRubric) NSLog(@"TPRubricQCellText dismissKeyboard %@", self.reuseIdentifier);
        [text resignFirstResponder];
    }
}

// =============================== UITextViewDelegate ===================================

// --------------------------------------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
    if (debugRubric) NSLog(@"TPRubricQCellText shouldChangeCharactersInRange %d", (int)textView);
    return [TPUtil shouldChangeTextInRange:range replacementText:string maxLength:10000];
}

// --------------------------------------------------------------------------------------
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    if (debugRubricText) NSLog(@"TPRubricQCellText textViewShouldBeginEditing %d", (int)textView);
    
    BOOL willEdit = [viewDelegate.model userCanEditQuestion:question];
    
    if (debugRubric) NSLog(@"TPRubricQCellText textViewShouldBeginEditing willEdit %d", willEdit);
    
    if (willEdit) {
        forceClose = NO;
        isEditing = YES;
        [self updateUI];
        [self reloadCell];
    }
    
    return willEdit;
}

// --------------------------------------------------------------------------------------
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (debugRubricText) NSLog(@"TPRubricQCellText textViewDidBeginEditing %d", (int)textView);
    viewDelegate.rubricVC.openTextView = textView; // Flag open text edit area
}

// --------------------------------------------------------------------------------------
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (debugRubricText) NSLog(@"TPRubricQCellText textViewShouldEndEditing %d %d", (int)textView, [viewDelegate.model isSetUILock]);
    if ([viewDelegate.model isSetUILock]) return NO;  // If lock set then ignore
	return YES;
}

// --------------------------------------------------------------------------------------
- (void)textViewDidEndEditing:(UITextView *)textView {
    
    if (debugRubricText) NSLog(@"TPRubricQCellText textViewDidEndEditing %d", (int)textView);
    
    isEditing = NO;
    [viewDelegate.model updateUserDataText:question text:text.text isAnnot:0];
    [self updateUI];
    [self reloadCell];
    
    // scroll to the next question
	if ([self isKindOfClass:[TPRubricQCell class]] && [viewDelegate.model autoScrolling]) {
		[((TPRubricQCell*)self) scrollToNextAction];
	}
	
    // Scroll content so we can see all in text area
    [text setContentOffset:CGPointMake(0.0, 0.0) animated:TRUE];
    
    viewDelegate.rubricVC.openTextView = nil; // Flag text editing as finished
}

@end

