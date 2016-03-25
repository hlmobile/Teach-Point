//
//  TPRubricQCellSignature.m
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
#import "TPRubricQCellSignature.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPAttachListVC.h" //jxi

// --------------------------------------------------------------------------------------
// TPRubricQCellSignature - return content of table cell for signature question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellSignature

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
            prompt.userInteractionEnabled = NO;
            prompt.textAlignment = TPTextAlignmentLeft;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
		}
        
		isSigned = [[viewDelegate.model questionText:question] length] && ![[viewDelegate.model questionText:question] isEqualToString:@"(null)"];
		
		if (isSigned) {
			signatureText = @"";
			timestamp = @"";
			
			NSString *signatureRaw = [viewDelegate.model questionText:question];
			NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[signatureRaw dataUsingEncoding:NSUTF8StringEncoding]];
			[parser setDelegate:self];
			[parser parse];
			[parser release];
		} else {
			signatureText = [viewDelegate.model getUserName:viewDelegate.model.appstate.user_id];
			timestamp = [viewDelegate.model stringFromDate:[NSDate date]];
		}
		
		containerView = [[UIView alloc] init];
        [containerView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [containerView.layer setBorderWidth:1.0f];
        containerView.backgroundColor = [UIColor whiteColor];
        if (prompt)
        {
            [containerView setFrame:CGRectMake(10, prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 100)];
        } else {
            [containerView setFrame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 100)];
        }
        
        constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize newTextSize1 = [signatureText sizeWithFont:[UIFont fontWithName:@"Zapfino" size:18.0]
                                        constrainedToSize:constSize
                                            lineBreakMode:TPLineBreakByWordWrapping];
		//UILabel *customSignatureLabel1 = [[UILabel alloc] init];
        UILabel *customSignatureLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(10, 10,
                                                                          newTextSize1.width,
                                                                          newTextSize1.height)];
		customSignatureLabel1.text = signatureText;
        customSignatureLabel1.backgroundColor = [UIColor clearColor];
		customSignatureLabel1.font = [UIFont fontWithName:@"Zapfino" size:18.0];
		customSignatureLabel1.textAlignment = TPTextAlignmentLeft;
		[customSignatureLabel1 setHidden:!isSigned];
        signatureLabel1 = customSignatureLabel1;
		[containerView addSubview:customSignatureLabel1];
        [customSignatureLabel1 release];
		
        NSString *signatureText2 = [NSString stringWithFormat:@"(%@ %@)", signatureText, [timestamp substringToIndex:16]];
		CGSize newTextSize2 = [signatureText2 sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                         constrainedToSize:constSize
                                             lineBreakMode:TPLineBreakByWordWrapping];
		//UILabel *customSignatureLabel2 = [[UILabel alloc] init];
        UILabel *customSignatureLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(10 + signatureLabel1.frame.size.width + 10,
                                                                          10 + 18,
                                                                          newTextSize2.width,
                                                                          newTextSize2.height)];
		customSignatureLabel2.text = signatureText2;
        customSignatureLabel2.backgroundColor = [UIColor clearColor];
		customSignatureLabel2.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		customSignatureLabel2.textAlignment = TPTextAlignmentLeft;
		[customSignatureLabel2 setHidden:!isSigned];
        signatureLabel2 = customSignatureLabel2;
		[containerView addSubview:customSignatureLabel2];
        [customSignatureLabel2 release];
        
		signButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [signButton setFrame:CGRectMake(10, 10, 100, 30)];
        
		[signButton addTarget:self action:@selector(signAction:) forControlEvents:UIControlEventTouchUpInside];
		[signButton setTitle:@"Sign" forState:UIControlStateNormal];
		[signButton setHidden:isSigned];
        [signButton setEnabled:[viewDelegate.model userCanEditQuestion:question]];
        if (!isCellEditable) [signButton setUserInteractionEnabled:NO];
		[containerView addSubview:signButton];
        
        if ([signButton isHidden]) {
            int containerViewHeight = ((signatureLabel1.frame.size.height > signatureLabel2.frame.size.height) ? (2.0 * signatureLabel1.frame.origin.y + signatureLabel1.frame.size.height) : (2.0 * signatureLabel2.frame.origin.y + signatureLabel2.frame.size.height));
            CGRect containerViewFrame = containerView.frame;
            [containerView setFrame:CGRectMake(containerViewFrame.origin.x,
                                               containerViewFrame.origin.y,
                                               containerViewFrame.size.width,
                                               containerViewHeight)];
        } else {
            CGRect containerViewFrame = containerView.frame;
            [containerView setFrame:CGRectMake(containerViewFrame.origin.x,
                                               containerViewFrame.origin.y,
                                               containerViewFrame.size.width,
                                               2.0 * signButton.frame.origin.y + signButton.frame.size.height)];
        }
        [self.contentView addSubview:containerView];
        cellHeight = containerView.frame.origin.y + containerView.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
		// scroll to top button and image
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, containerView.frame.origin.y + containerView.frame.size.height + 10, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
            cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        }
        
        //jxi; Add attchlist button
        attachlistButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 110, containerView.frame.origin.y + containerView.frame.size.height + 10, 30, 30)];
        attachlistImage = [UIImage imageNamed:@"paperclip.png"];
        [attachlistButton setImage:attachlistImage forState:UIControlStateNormal];
        [attachlistButton addTarget:self action:@selector(showAttachListPO) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:attachlistButton];
        
        //jxi; Add attachment list
        attachListVC = [[TPAttachListVC alloc]initWithViewDelegate:viewDelegate
                                                            parent:self
                                                     containerType:TP_ATTACHLIST_CONTAINER_TYPE_QUESTION
                                              parentFormUserDataID:viewDelegate.model.appstate.userdata_id parentQuestionID:question.question_id];
        attachListVC.view.frame = CGRectMake(10, containerView.frame.origin.y + containerView.frame.size.height + 10, 320, attachListVC.attachListHeight);
        [self.contentView addSubview:attachListVC.view];
        
        [self updateUI];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [title release];
    if (prompt) {
        [prompt release];
        prompt = NULL;
    }
	[signatureLabel1 release];
	[signatureLabel2 release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    // title
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
    
    // container view
    CGRect containerViewFrame = containerView.frame;
    [containerView setFrame:CGRectMake(containerViewFrame.origin.x,
                                       containerViewFrame.origin.y,
                                       aCellWidth,
                                       containerViewFrame.size.height)];
    
    float attachistButtonX = aCellWidth - 20; //jxi;
    
    // nextButton
    if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, containerView.frame.origin.y + containerView.frame.size.height + 10, 30, 30)];
        cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
        attachistButtonX = aCellWidth - 65; //jxi;
    } else {
        cellHeight = containerView.frame.origin.y + containerView.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    }
    
    // jxi;
    attachlistButton.frame = CGRectMake(attachistButtonX, containerView.frame.origin.y + containerView.frame.size.height + 10, 30, 30);
    attachListVC.view.frame = CGRectMake(10, containerView.frame.origin.y + containerView.frame.size.height + 10, 320, attachListVC.attachListHeight);
    
    if (attachListVC.attachListHeight > attachlistButton.frame.size.height)
        cellHeight = attachListVC.view.frame.origin.y + attachListVC.attachListHeight + TP_QUESTION_AFTER_QUESTION_MARGIN;
    else
        cellHeight = attachlistButton.frame.origin.y + attachlistButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    
}

// --------------------------------------------------------------------------------------
-(void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

// --------------------------------------------------------------------------------------
- (void)signAction:(id)sender {
	UIAlertView *alert;
    
    if (question.type == TP_QUESTION_TYPE_SIGNATURE_RESTRICTED) {
        alert = [[UIAlertView alloc] initWithTitle:@""
                                           message:@"Do you want to sign this form? After signing you will no longer be able to make further edits."
                                          delegate:self
                                 cancelButtonTitle:@"Yes"
                                 otherButtonTitles: @"No", nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@""
                                           message:@"Do you want to sign this form?"
                                          delegate:self
                                 cancelButtonTitle:@"Yes"
                                 otherButtonTitles: @"No", nil];
    }
    
	[alert show];
	[alert release];
}

// --------------------------------------------------------------------------------------
- (void) stopElapsedTime {
    
	//TPUserData *userdata = [viewDelegate.model getUserDataFromListById:viewDelegate.model.appstate.userdata_id];
    TPUserData *userdata = [viewDelegate.model getCurrentUserData];
	
	if (viewDelegate.model.appstate.user_id  == userdata.user_id) {
		// signed by owner
		[((TPRubricQCellSubHeading*)viewDelegate.rubricVC.tableView.tableHeaderView) stopElapsedTime];
	}
}


// ============================== UIAlertViewDelegate ===================================

// --------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // Ignore if not logged in or in timeout
    // WARNING we shouldn't need this.  We should dismiss all alerts before entering background
    if ([viewDelegate.model.publicstate.state isEqualToString:@"install"] ||
        [viewDelegate.model.publicstate.state isEqualToString:@"timeout"]) return;
    
	if (buttonIndex == 0) {
		isSigned = TRUE;
		[signButton setHidden:isSigned];
		[signatureLabel1 setHidden:!isSigned];
		[signatureLabel2 setHidden:!isSigned];
		
		NSString *timestamp2 = [viewDelegate.model stringFromDate:[NSDate date]];
		NSString *signatureText2 = [NSString stringWithFormat:@"<signature user_id=\"%d\">%@</signature>", viewDelegate.model.appstate.user_id, timestamp2];
		[viewDelegate.model updateUserDataText:question text:signatureText2 isAnnot:0];
        [viewDelegate.model userHasSignedQuestion:question];
		
		[self updateModified];
		[self stopElapsedTime];
        [viewDelegate rubricDoneEditing];
	}
}

// --------------------------------------------------------------------------------------
//NSXMLParser delegates
- (void)parser:(NSXMLParser* )parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    
    if([elementName isEqual:@"signature"]) {
		int user_id = [[NSString stringWithString:[attributeDict valueForKey:@"user_id"]] intValue];
		signatureText = [viewDelegate.model getUserName:user_id];
	}
}

// --------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    timestamp = [NSString stringWithString:string];
}

@end
