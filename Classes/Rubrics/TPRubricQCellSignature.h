//
//  TPRubricQCellSignature.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCell;

// --------------------------------------------------------------------------------------
// TPRubricQCellSignature - return content of table cell for signature question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellSignature : TPRubricQCell <NSXMLParserDelegate, UIAlertViewDelegate> {
	BOOL isSigned, isAuthorized;
	NSString *signatureText, *timestamp;
	UIButton *signButton;
	UILabel *signatureLabel1;
	UILabel *signatureLabel2;
    UIView *containerView;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
- (void) stopElapsedTime;

@end

