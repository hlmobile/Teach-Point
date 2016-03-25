//
//  TPAttachListVC.h
//  teachpoint
//
//  Created by Jinzhe xi on 8/2/13.
//
//

#import <UIKit/UIKit.h>

#define TP_ATTACHLIST_CONTAINER_TYPE_FORM			1 //jxi
#define TP_ATTACHLIST_CONTAINER_TYPE_QUESTION		2 //jxi

@class TPView;

@interface TPAttachListVC : UIViewController {
    
    TPView *viewDelegate;
    id container; // store the parent rubricQcell or rubricVC
    
    int container_type;
    NSString *aud_id; // Parent form's userdata_id
    int aq_id; // Parent question's id
 
    NSMutableArray *attach_list; // List of attachment userdata
    float attachListHeight; // Height of the ListVC
    
    UIView *backgroundView;
}

@property (readonly) float attachListHeight;
@property (readonly) NSMutableArray *attach_list;
@property (nonatomic, retain) NSString *aud_id;
@property (nonatomic) int aq_id;

- (id) initWithViewDelegate:(TPView *)delegate parent:(id)parent containerType:(int)containerType  parentFormUserDataID:(NSString *)audId parentQuestionID:(int) aqId;

- (void) reset;
- (void) updateUI;
@end
