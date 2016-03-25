@class TPPublicState;
@class TPAppState;
@class TPPublicState;
@class TPUser;
@class TPUserInfo;
@class TPCategory;
@class TPRubric;
@class TPQuestion;
@class TPRating;
@class TPUserData;
@class TPRubricData;
@class TPModel;
@class TPImage;
@class TPVideo; //jxi;

@interface TPParser : NSObject <NSXMLParserDelegate> {
	
	TPModel *model;
	
    // Pointers to arrays to store parsed objects in
    TPPublicState   *publicstate;
	TPAppState      *appstate;
	NSMutableArray  *users;
    NSMutableArray  *info;
    NSMutableArray  *categories;
	NSMutableArray  *rubrics;
    NSMutableArray  *questions;
    NSMutableArray  *ratings;
    NSMutableArray  *userdata;
    
    //NSMutableArray  *thumbnails; // array of TPImage objects that were created from parsed thumbnails
    //TPUserData      *imagedata;
    //TPImage         *full_image;
    
    // Temporary objects to fill during parse of XML
    TPAppState      *current_appstate;
	TPUser          *current_user;
    TPUserInfo      *current_info;
    TPCategory      *current_category;
	TPRubric        *current_rubric;
    TPQuestion      *current_question;
    TPRating        *current_rating;
    TPUserData      *current_userdata;
    TPRubricData    *current_rubricdata;
    TPImage         *current_image;
    TPVideo         *current_video; //jxi;
    
    //TPImage         *current_image;
    //TPImage         *current_full_image;
    //TPUserData      *current_imagedata;

    // Temporary string holding content between tags
	NSMutableString *current_property;
}

- (id)initWithModel:(TPModel *)somemodel;

- (void) resetparser;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName;

@end
