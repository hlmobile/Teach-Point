//
//  TPRubricQCellTimer.m
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
#import "TPRubricQCellTimer.h"
#import "TPUtil.h"
#import "TPCompat.h"

// --------------------------------------------------------------------------------------
// TPRubricQCellTimer - return content of table cell for timer question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellTimer

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
        showAnnotation = FALSE;
        annotEditable = NO;
        
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
		
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		
		
		title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
		title.text = question.title;
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
            prompt.numberOfLines = 0;
            prompt.lineBreakMode = TPLineBreakByWordWrapping;
            prompt.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            prompt.userInteractionEnabled = NO;
            prompt.textAlignment = TPTextAlignmentLeft;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
		}
        
		elapsedTime = [[viewDelegate.model questionText:question] intValue];
        
        containerView = [[UIView alloc] init];
        [containerView.layer setBorderWidth:1.0f];
        [containerView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        
        if (prompt) {
            [containerView setFrame:CGRectMake(10, prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 50)];
        } else {
            [containerView setFrame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 50)];
        }
        UILabel *customTimeLabel = [[UILabel alloc] init];
        [customTimeLabel setFrame:CGRectMake(10, 10, 100, 20)];
		customTimeLabel.text = [TPUtil formatElapsedTime:elapsedTime];
		customTimeLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		customTimeLabel.textAlignment = TPTextAlignmentLeft;
        customTimeLabel.backgroundColor = [UIColor clearColor];
        timeLabel = customTimeLabel;
        [containerView addSubview:customTimeLabel];
        
        CGRect containerViewFrame = containerView.frame;
        [containerView setFrame:CGRectMake(containerViewFrame.origin.x,
                                           containerViewFrame.origin.y,
                                           containerViewFrame.size.width,
                                           timeLabel.frame.origin.y + timeLabel.frame.size.height + 10)];
		
        //TPUserData *userdata = [viewDelegate.model getUserDataFromListById:viewDelegate.model.appstate.userdata_id];
        TPUserData *userdata = [viewDelegate.model getCurrentUserData];
        
        if (userdata.user_id == viewDelegate.model.appstate.user_id) {
			UIButton *customStartStopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [customStartStopButton setFrame:CGRectMake(120, 10, 100, 30)];
            [customStartStopButton addTarget:self action:@selector(startStopTime) forControlEvents:UIControlEventTouchUpInside];
			[customStartStopButton setTitle:@"Start" forState:UIControlStateNormal];
			//[customStartStopButton setHidden:![viewDelegate.model userCanEditQuestion:FALSE :FALSE]];
            [customStartStopButton setHidden:![viewDelegate.model userCanEditQuestion:question]];
            startStopButton = customStartStopButton;
            if (!isCellEditable) [startStopButton setUserInteractionEnabled:NO];
        	[containerView addSubview:customStartStopButton];
            
            CGRect containerViewFrame = containerView.frame;
            [containerView setFrame:CGRectMake(containerViewFrame.origin.x,
                                               containerViewFrame.origin.y,
                                               containerViewFrame.size.width,
                                               startStopButton.frame.origin.y + startStopButton.frame.size.height + 10)];
        }
        
        [self.contentView addSubview:containerView];
        
        cellHeight = containerView.frame.origin.y + containerView.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        int buttonsBaseY = containerView.frame.origin.y + containerView.frame.size.height;
        
        CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                     constrainedToSize:constSize
                                                                         lineBreakMode:TPLineBreakByWordWrapping];
        annotText = [[UITextView alloc] initWithFrame:CGRectMake(10, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
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
        
        if (question.annotation) {
            annotButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [annotButton setFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 160, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
            [annotButton addTarget:self action:@selector(toggleAnnotAction:) forControlEvents:UIControlEventTouchUpInside];
            [annotButton setTitle:@"Annotate" forState:UIControlStateNormal];
            [self.contentView addSubview:annotButton];
        }
        
		// scroll to top button and image
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
            cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        }
        
        [self updateUI];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    //title
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
                                 constrainedToSize:constSize
                                     lineBreakMode:TPLineBreakByWordWrapping];
    [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, aCellWidth, textSize.height)];
    // prompt
    if (prompt) {
        textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                               constrainedToSize:constSize
                                   lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                    aCellWidth,
                                    textSize.height)];
    }
    // startStopButton + timeLabel
    //    int buttonsBaseY;
    //    if (startStopButton)
    //    {
    //        buttonsBaseY = startStopButton.frame.origin.y + startStopButton.frame.size.height;
    //    }
    //    else
    //    {
    //        buttonsBaseY = timeLabel.frame.origin.y + timeLabel.frame.size.height;
    //    }
    
    // containerView
    int containerViewHeight;
    if (startStopButton) {
        containerViewHeight = startStopButton.frame.origin.y + startStopButton.frame.size.height + 10;
    } else {
        containerViewHeight = timeLabel.frame.origin.y + timeLabel.frame.size.height + 10;
    }
    
    if (prompt) {
        [containerView setFrame:CGRectMake(10,
                                           prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                           aCellWidth,
                                           containerViewHeight)];
    } else {
        [containerView setFrame:CGRectMake(10,
                                           title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                           aCellWidth,
                                           containerViewHeight)];
    }
    
    cellHeight = containerView.frame.origin.y + containerView.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    int buttonsBaseY = containerView.frame.origin.y + containerView.frame.size.height;
    
    
    // annotation
    if (question.annotation) {
        //  show annotation text
        if (showAnnotation) {
            CGSize constSize = CGSizeMake(aCellWidth, 1000);
            CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                         constrainedToSize:constSize
                                                                             lineBreakMode:TPLineBreakByWordWrapping];
            if (annotEditable) {
                [annotText setFrame:CGRectMake(10, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, aCellWidth, (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED)];
            }
            else {
                [annotText setFrame:CGRectMake(10, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, aCellWidth, (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
            }
            buttonsBaseY = annotText.frame.origin.y + annotText.frame.size.height;
            cellHeight = buttonsBaseY + TP_QUESTION_AFTER_QUESTION_MARGIN;
            [annotButton setHidden:YES];
            [annotText setHidden:NO];
        } else {
            // show annotation button
            [annotButton setFrame:CGRectMake(aCellWidth - 160, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
            [annotButton setHidden:NO];
            [annotText setHidden:YES];
            cellHeight = annotButton.frame.origin.y + annotButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        }
        
    }
    // nextButton
    if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20,  buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
        cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
	}
}

// --------------------------------------------------------------------------------------
// show annotation button
-(void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

// --------------------------------------------------------------------------------------
- (void)startStopTime {
	// updating elapsed time for rubrics owner
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
	if (!secondTimer) {
		secondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(everySecond) userInfo:nil repeats:YES];
		[startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self updateModified];
	} else {
		[secondTimer invalidate];
		secondTimer = nil;
		[startStopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self updateModified];
	}
}

// --------------------------------------------------------------------------------------
// show annotation button
- (void)everySecond {
	elapsedTime++;
	timeLabel.text = [TPUtil formatElapsedTime:elapsedTime];
}

// --------------------------------------------------------------------------------------
// show annotation button
- (void)saveTime {
	if (elapsedTime && elapsedTime != [[viewDelegate.model questionText:question] intValue]) {
		[viewDelegate.model updateUserDataText:question text:[NSString stringWithFormat:@"%d", elapsedTime] isAnnot:1];
	}
}

// --------------------------------------------------------------------------------------
// show annotation button
- (void) dealloc {
    [title release];
    if (prompt) {
        [prompt release];
        prompt = NULL;
    }
	[timeLabel release];
	
	if (secondTimer) {
		[secondTimer invalidate];
		secondTimer = nil;
	}
	[super dealloc];
}

@end
