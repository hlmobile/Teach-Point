@class TPPublicState;
@class TPAppState;
@class TPUser;
@class TPRubric;
@class TPQuestion;
@class TPRating;
@class TPModel;

// --------------------------------------------------------------------------------------
// Debug constants to turn on debug console messages
// --------------------------------------------------------------------------------------
static const int debugAppStart = 0;
static const int debugLock = 0;

static const int debugView = 0;
static const int debugLogin = 0;
static const int debugRotate = 0;

static const int debugMaster = 0;
static const int debugRubric = 0;
static const int debugRubricText = 0;
static const int debugRubricList = 0;
static const int debugCamera = 0;
static const int debugPreview = 0;
static const int debugReport = 0;

static const int debugDatabaseControl = 0;
static const int debugDatabase = 0;
static const int debugDatabaseDetail = 0;

static const int debugData = 0;
static const int debugModel = 0;
static const int debugCrypt = 0;
static const int debugArchive = 0;

static const int debugSync = 0;
static const int debugSyncControl = 0;
static const int debugSyncStatus = 0;
static const int debugSyncDetail = 0;
static const int debugSyncConn = 0;
static const int debugSyncUDHandle = 0;
static const int debugSyncMgr = 0;
static const int debugParser = 0;

static const int debugAttachListVC = 0; //jxi;
static const int debugAttachListPO = 0; //jxi;

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
typedef enum {
    TP_QUESTION_TYPE_NONE = 0,
    TP_QUESTION_TYPE_RATING = 1,
    TP_QUESTION_TYPE_TEXT = 2,
    TP_QUESTION_TYPE_HEADING = 3,
    TP_QUESTION_TYPE_INSTRUCTIONS = 4,
    TP_QUESTION_TYPE_UNISELECT = 5,
    TP_QUESTION_TYPE_MULTISELECT = 6,
    TP_QUESTION_TYPE_SIGNATURE_RESTRICTED = 7,
    TP_QUESTION_TYPE_TIMER = 9,
    TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE = 10,
    TP_QUESTION_TYPE_DATE = 12,
    TP_QUESTION_TYPE_TIME = 13,
    TP_QUESTION_TYPE_DATE_TIME = 14
} TPQuestionTypes;

typedef enum {
    TP_QUESTION_SUBTYPE_NORMAL = 0,
    TP_QUESTION_SUBTYPE_REFLECTION = 1,
    TP_QUESTION_SUBTYPE_THIRDPARTY = 2,
    TP_QUESTION_SUBTYPE_READONLY = 3,
    TP_QUESTION_SUBTYPE_ANYONE = 4,
    TP_QUESTION_SUBTYPE_COMPUTED = 5
} TPQuestionSubtypes;

typedef enum {
    TP_RUBRIC_TYPE_NORMAL = 0,
    TP_RUBRIC_TYPE_READONLY = 1
} TPRubricTypes;

typedef enum {
    TP_RUBRIC_DELETED_STATE = 0,
    TP_RUBRIC_UNPUBLISHED_STATE = 1,
    TP_RUBRIC_PUBLISHED_STATE = 2,
    TP_RUBRIC_SUPERSEDED_STATE = 3
} TPRubricStateTypes;

typedef enum {
    TP_USERDATA_TYPE_UNDEFINED = 0,
    TP_USERDATA_TYPE_FORM = 1,
    TP_USERDATA_TYPE_IMAGE = 3,
    TP_USERDATA_TYPE_VIDEO = 4, //jxi;
    TP_USERDATA_TYPE_ATTACHMENT = 5
} TPUserdataTypes;

typedef enum {
    TP_USERDATA_DELETED_STATE = 0,
    TP_USERDATA_EMPTY_STATE = 1,
    TP_USERDATA_PARTIAL_STATE = 2,
    TP_USERDATA_COMPLETE = 3,
    TP_USERDATA_SYNCED_PARTIAL_STATE = 12,
    TP_USERDATA_SYNCED_COMPLETE_STATE = 13,
    TP_USERDATA_RESEND_REQUEST = 99,
    TP_USERDATA_NODATA_STATE = 14, //jxi;
} TPUserdataStateTypes;

typedef enum {
    TP_PERMISSION_UNKNOWN = 0,
    TP_PERMISSION_VIEW = 1,
    TP_PERMISSION_VIEW_AND_RECORD = 2,
    TP_PERMISSION_RECORD = 3
} TPPermissionTypes;

typedef enum {
    TP_IMAGE_TYPE_UNKNOWN = 0,
    TP_IMAGE_TYPE_FULL = 1,
    TP_IMAGE_TYPE_THUMBNAIL = 2
} TPImageTypes;

typedef enum {
    TP_IMAGE_ORIGIN_LOCAL = 0,
    TP_IMAGE_ORIGIN_REMOTE = 1
} TPImageOriginTypes;

typedef enum {
    TP_USER_FORM_PERMISSION_UNKNOWN = 0,
    TP_USER_FORM_PERMISSION_OWNER = 1,
    TP_USER_FORM_PERMISSION_SUBJECT = 2,
    TP_USER_FORM_PERMISSION_THIRDPARTY = 3
} TPUserTypeForSelectedForm;

// --------------------------------------------------------------------------------------
// TPPublicState - current publicly viewable state of application.
// --------------------------------------------------------------------------------------
@interface TPPublicState : NSObject <NSCoding> {
	NSString *state;		   // state string (install, sync, rubriclist, ...)
    NSString *district_name;   // district name
    NSString *first_name;      // user's first name
    NSString *last_name;       // user's last name
    NSString *hashed_password; // hashed password
    int is_demo;               // flag if demo account (1=yes, 0=no)
}

@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *district_name;
@property (nonatomic, retain) NSString *first_name;
@property (nonatomic, retain) NSString *last_name;
@property (nonatomic, retain) NSString *hashed_password;
@property (nonatomic) int is_demo;

- (id) init;

@end

// --------------------------------------------------------------------------------------
// TPAppState - current state of application.
// --------------------------------------------------------------------------------------
@interface TPAppState : NSObject <NSCoding> {
	NSString *state;		 // install, usersync, datasync, rubric
    NSString *districtlogin; // District login nickname
	NSString *login;		 // Login name
	NSString *password;      // Login password
	NSString *sync_status;	 // sync status (eg. loginvalid, loginwarning, loginfailed)
	NSString *sync_message;  // sync message to be displayed if loginwarning or loginfailure
    int user_id;
    NSString *first_name;
    NSString *last_name;
    int district_id;
    NSString *district_name; // district name
	int target_id;			 // current teacher
	int rubric_id;           // current rubric
    NSString *userdata_id;   // current rubric instance
    int can_edit;            // indicate if user can edit current rubric instance
    NSDate *last_sync;       // time of last sync, if not null then auto-sync
    NSDate *last_sync_completed;       // time of last sync completed
    int user_sort;           // User sort key (0=name, 1=school, 2=grade)
    int lock;                // lock set when user input should not be processed (set during parts of sync process)
}

@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *districtlogin;
@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *sync_status;
@property (nonatomic, retain) NSString *sync_message;
@property (nonatomic) int user_id;
@property (nonatomic, retain) NSString *first_name;
@property (nonatomic, retain) NSString *last_name;
@property (nonatomic) int district_id;
@property (nonatomic, retain) NSString *district_name;
@property (nonatomic) int target_id;
@property (nonatomic) int rubric_id;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic) int can_edit;
@property (nonatomic, retain) NSDate *last_sync;
@property (nonatomic, retain) NSDate *last_sync_completed;
@property (nonatomic) int user_sort;
@property (nonatomic) int lock;

- (id) init;

@end

// --------------------------------------------------------------------------------------
// TPUser - type 0=sys-admin, 1=district-admin, 2=administrator, 3=teacher
// --------------------------------------------------------------------------------------
@interface TPUser : NSObject <NSCoding> {
	int user_id;
    int type;
    int permission;
	NSString *first_name;
	NSString *last_name;
	NSString *job_position;
    int school_id;
	NSString *schools;
    int grade_min;
    int grade_max;
    int subject_id;
    NSString *subjects;
    int first_year;
    int first_year_in_district;
    NSString *professional_status;
    NSString *employee_id;
    NSString *email;
    int state;
    NSDate *modified;
    int total_forms;
    int total_elapsed;
}

@property (nonatomic) int user_id;
@property (nonatomic) int type;
@property (nonatomic) int permission;
@property (nonatomic, retain) NSString *first_name;
@property (nonatomic, retain) NSString *last_name;
@property (nonatomic, retain) NSString *job_position;
@property (nonatomic) int school_id;
@property (nonatomic, retain) NSString *schools;
@property (nonatomic) int grade_min;
@property (nonatomic) int grade_max;
@property (nonatomic) int subject_id;
@property (nonatomic, retain) NSString *subjects;
@property (nonatomic) int first_year;
@property (nonatomic) int first_year_in_district;
@property (nonatomic, retain) NSString *professional_status;
@property (nonatomic, retain) NSString *employee_id;
@property (nonatomic, retain) NSString *email;
@property (nonatomic) int state;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic) int total_forms;
@property (nonatomic) int total_elapsed;

- (NSString *) getDisplayName;
- (NSString *) getGradeString;
- (NSString *) getGradeStringShort;
- (NSString *) getGradePickerStringByIndex:(int)index;
- (int) getGradeIdByPickerIndex:(int)index;
- (int) getGradeRangeSize;
+ (NSString *) getGradeStringById:(int)gradeId;
+ (NSString *) getGradeStringByAdjustedValue:(int)value;
+ (NSString *) getGradeFullStringByAdjustedValue:(int)value;
+ (int) getGradeAdjustedValue:(int)gradeId;

@end

// --------------------------------------------------------------------------------------
// TPUserInfo - user info
// --------------------------------------------------------------------------------------
@interface TPUserInfo : NSObject <NSCoding> {
	int user_id;
    int type;
    NSString *info;
    NSDate *modified;
}

@property (nonatomic) int user_id;
@property (nonatomic) int type;
@property (nonatomic, retain) NSString *info;
@property (nonatomic, retain) NSDate *modified;

@end

// --------------------------------------------------------------------------------------
// TPCategory - category
// --------------------------------------------------------------------------------------
@interface TPCategory : NSObject <NSCoding> {
	int category_id;
    NSString *name;
    int corder;
    int state;
    NSDate *modified;
}

@property (nonatomic) int category_id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic) int corder;
@property (nonatomic) int state;
@property (nonatomic, retain) NSDate *modified;

@end

// --------------------------------------------------------------------------------------
// TPRubric - rubric.
// --------------------------------------------------------------------------------------
@interface TPRubric : NSObject <NSCoding> {
	int rubric_id;
	NSString *title;
    int rec_stats;
    int rec_elapsed;
    int version;
    int state;
    int type;
    NSDate *modified;
    int rorder;
    NSString *group;
}

@property (nonatomic) int rubric_id;
@property (nonatomic, retain) NSString *title;
@property (nonatomic) int rec_stats;
@property (nonatomic) int rec_elapsed;
@property (nonatomic) int version;
@property (nonatomic) int state;
@property (nonatomic) int type;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic) int rorder;
@property (nonatomic, retain) NSString *group;

-(BOOL) isRubricEditable;

@end

// --------------------------------------------------------------------------------------
// TPQuestion - rubric question.
// --------------------------------------------------------------------------------------
@interface TPQuestion : NSObject <NSCoding> {
    int question_id;
	int rubric_id;
    int order;
    int type;
    int subtype;
    int category;
    int optional;
	NSString *title;
    NSString *prompt;
    NSMutableDictionary *style;
    NSMutableDictionary *title_style;
    NSMutableDictionary *prompt_style;
    int annotation;
}

@property (nonatomic) int question_id;
@property (nonatomic) int rubric_id;
@property (nonatomic) int order;
@property (nonatomic) int type;
@property (nonatomic) int subtype;
@property (nonatomic) int category;
@property (nonatomic) int optional;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *prompt;
@property (nonatomic, retain) NSMutableDictionary *style;
@property (nonatomic, retain) NSMutableDictionary *title_style;
@property (nonatomic, retain) NSMutableDictionary *prompt_style;
@property (nonatomic) int annotation;

+ (NSMutableDictionary *) styleWithString: (NSString *) string;
- (BOOL) isQuestionEditable;
- (BOOL) isQuestionReflection;
- (BOOL) isQuestionThirdparty;

@end

// --------------------------------------------------------------------------------------
// TPRating - rubric question rating.
// --------------------------------------------------------------------------------------
@interface TPRating : NSObject <NSCoding> {
    int rating_id;
    int question_id;
	int rubric_id;
    int rorder;
    float value;
    NSString *text;
    NSString *title;
}

@property (nonatomic) int rating_id;
@property (nonatomic) int question_id;
@property (nonatomic) int rubric_id;
@property (nonatomic) int rorder;
@property (nonatomic) float value;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *title;

+ (NSString *) getDefaultRatingScaleTitle:(int)order;

@end

// --------------------------------------------------------------------------------------
//  TPUserData - recorded object (rubric, note, etc.)
//    States are 0=opened, 1=edited, 2=data, 3=complete
// --------------------------------------------------------------------------------------
@interface TPUserData : NSObject {
    int district_id;
	int user_id;
    int target_id;
    int share;
    int school_id;
    int subject_id;
    int grade;
    int elapsed;
    int type;
    int rubric_id;
    NSString *name;
    NSString *userdata_id;
    int state;
    NSDate *created;
	NSDate *modified;
    NSMutableArray *rubricdata;
    NSString *description;
    NSString *aud_id; //jxi
    int aq_id; //jxi
}

@property (nonatomic) int district_id;
@property (nonatomic) int user_id;
@property (nonatomic) int target_id;
@property (nonatomic) int share;
@property (nonatomic) int school_id;
@property (nonatomic) int subject_id;
@property (nonatomic) int grade;
@property (nonatomic) int elapsed;
@property (nonatomic) int type;
@property (nonatomic) int rubric_id;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic) int state;
@property (nonatomic, retain) NSDate *created;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic, retain) NSMutableArray *rubricdata;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *aud_id; //jxi
@property (nonatomic) int aq_id; //jxi

+ (NSString *)generateUserdataIDWithModel:(TPModel *)aModel creationDate:(NSDate *)aDate type:(int)aType;

- (id) init;
- (id) initWithModel:(TPModel *)model name:(NSString *)somename rubricId:(int)rubricId type:(int)sometype;
- (id) initWithModel:(TPModel *)aModel userdataID:(NSString *)aUserdataID name:(NSString *)aName share:(int)aShare description:(NSString *)description creationDate:(NSDate *)aDate type:(int)aType;
- (id) initWithModel:(TPModel *)aModel userdataID:(NSString *)aUserdataID name:(NSString *)aName share:(int)aShare description:(NSString *)description creationDate:(NSDate *)aDate type:(int)aType aAud_id:(NSString *)aAud_id aAq_id:(int)aAq_id; //jxi;
- (id) initWithUserData:(TPUserData *)userdata;

@end

// --------------------------------------------------------------------------------------
// TPRubricData - recorded rubric question
// --------------------------------------------------------------------------------------
@interface TPRubricData : NSObject {
	int district_id;
	NSString *userdata_id;
	int rubric_id;
    int question_id;
    int rating_id;
    float value;
    NSString *text;
    int annotation;
    int user;
    NSDate *modified;
    NSDate *datevalue;
}

@property (nonatomic) int district_id;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic) int rubric_id;
@property (nonatomic) int question_id;
@property (nonatomic) int rating_id;
@property (nonatomic) float value;
@property (nonatomic, retain) NSString *text;
@property (nonatomic) int annotation;
@property (nonatomic) int user;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic, retain) NSDate *datevalue;

- (id) initWithModel:(TPModel *)model rating:(TPRating *)rating;
- (id) initWithModel:(TPModel *)model question:(TPQuestion *)question text:(NSString *)sometext;
- (id) initWithModel:(TPModel *)model question:(TPQuestion *)question text:(NSString *)sometext annotation:(int)annot;

@end

// --------------------------------------------------------------------------------------
// TPImage - recorded image
// --------------------------------------------------------------------------------------
@interface TPImage : NSObject {
    int district_id;
    NSString *userdata_id;
    int type;
    int width;
    int height;
    NSString *format;
    NSString *encoding;
    int user_id;
    NSDate *modified;
    UIImage *image;
    NSString *filename;
    int origin;
}

@property (nonatomic) int district_id;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic) int type;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic, retain) NSString *format;
@property (nonatomic, retain) NSString *encoding;
@property (nonatomic) int user_id;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic) int origin;

- (id) initWithImage:(UIImage *)someimage
          districtId:(int)districtId
          userdataID:(NSString *)userdataId 
                type:(int)typeVal
               width:(int)widthVal
              height:(int)heightVal
              format:(NSString *)formatVal
            encoding:(NSString *)encodingVal
              userId:(int)userId
            modified:(NSDate *)modifiedDate
            filename:(NSString *)fileName
              origin:(int)origin;
    
- (UIImage *)createThumbnailImage;
- (BOOL)isPortraitImage;
- (NSComparisonResult) compareModifiedDate:(TPImage *)image;

@end
// --------------------------------------------------------------------------------------

//jxi;
// --------------------------------------------------------------------------------------
// TPVideo - recorded Video
// --------------------------------------------------------------------------------------
@interface TPVideo : NSObject {
    int district_id;
    NSString *userdata_id;
    int type;
    int width;
    int height;
    NSString *format;
    NSString *encoding;
    int user_id;
    NSDate *modified;
    NSURL *videoUrl;
    NSString *filename;
    UIImage *thumbImage;
    int origin;
}

@property (nonatomic) int district_id;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic) int type;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic, retain) NSString *format;
@property (nonatomic, retain) NSString *encoding;
@property (nonatomic) int user_id;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic, retain) NSURL *videoUrl;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) UIImage *thumbImage;
@property (nonatomic) int origin;

- (id) initWithImage:(NSURL *)someVideo
          districtId:(int)districtId
          userdataID:(NSString *)userdataId
                type:(int)typeVal
               width:(int)widthVal
              height:(int)heightVal
              format:(NSString *)formatVal
            encoding:(NSString *)encodingVal
              userId:(int)userId
            modified:(NSDate *)modifiedDate
            filename:(NSString *)fileName
              origin:(int)origin;

- (UIImage *)createThumbnailImage;
- (UIImage *)thumbnailImage;
- (BOOL)isPortraitImage;
- (NSComparisonResult) compareModifiedDate:(TPVideo *)video;

@end
