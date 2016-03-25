@class TPView;

// --------------------------------------------------------------------------------------
@interface TPReportVC : UIViewController <UIWebViewDelegate, UIScrollViewDelegate> {
    
    TPView *viewDelegate;
    
    UIBarButtonItem *rightbutton;
    UIScrollView *scrollView;
    UIWebView *webView;
}

- (id)initWithView:(TPView *)mainview;
- (void) reset:(int)reportgroup groupName:(NSString *)groupName reportId:(int)reportId reportName:(NSString *)reportName;
- (NSString *) individualPerformanceReportByRubric;
- (void) addDetailRubric:(NSMutableString *)report targetUser:(TPUser *)targetUser categoryIdList:(NSMutableArray *)categoryIdList rubricId:(int)rubricId;
- (NSString *) performanceComparisonReportByRubric:(int)rubricId rubricName:(NSString *)rubricName;
- (NSString *) rubricCompletedReport;
- (NSString *) advancedRubricReport:(int)rubricId rubricName:(NSString *)rubricName;
- (NSString *) getReportBarChartStyle;
- (NSString *) getReportBarChart:(NSString *)questionTitle totalRecorded:(int)totalRecorded entries:(NSArray *)entries;
- (NSString *) getRatingsReportBarChart:(NSString *)questionTitle totalRecorded:(int)totalRecorded entries:(NSArray *)entries;
- (NSString *) getElapsedTable:(int)rubricId datesList:(NSMutableArray *)datesList evaluatorList:(NSMutableArray *)evaluatorList elapsedList:(NSMutableArray *)elapsedList;
- (NSString *) getTextListing:(NSString *)questionTitle entries:(NSArray *)entries;
- (NSString *) getReportHeader:(NSString *)reportTitle;

@end

// --------------------------------------------------------------------------------------
@interface TPReportTableEntry : NSObject {
    NSString *text;
    int count;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic) int count;

@end
    
// --------------------------------------------------------------------------------------
