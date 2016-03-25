//
//  TPAttachListPO.h
//  teachpoint
//
//  Created by Jinzhe xi on 8/3/13.
//
//

#import <UIKit/UIKit.h>

@class TPView;

@interface TPAttachListPO : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    TPView *viewDelegate;
    
    UITableView *table;
    
    UIToolbar *toolbar;
    UIBarButtonItem *captureButton;
    
    NSMutableArray *attach_list; // List of attachment userdata
}

- (id) initWithViewDelegate:(TPView *)delegate;
- (void) reset;

@end
