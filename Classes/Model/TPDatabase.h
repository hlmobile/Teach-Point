#import <sqlite3.h>
#import "TPModel.h"
#import "NSData+Base64.h"

@class TPModel;
@class TPQuestion;
@class TPRating;
@class TPImage;

// --------------------------------------------------------------------------------------
@interface TPDatabase : NSObject {

	TPModel *model;
	sqlite3 *database;
    NSString *imagesPath;
    NSString *videosPath; //jxi;
    
    NSDateFormatter *dateformatter;
    NSLocale *dateLocal;
    NSLock *dateformatterLock;
}

@property (nonatomic, retain) NSString *imagesPath;
@property (nonatomic, retain) NSString *videosPath; //jxi;

- (id) initWithModel:(TPModel *)some_model;

// Basic operations
- (void) initDatabase;

- (void) closeDatabase;
+ (void) destroyDatabase;
+ (void) deleteAllImageFiles;
+ (void) deleteAllVideoFiles; //jxi;
- (void) clear;

- (void) dumpDatabase;
- (void) dumpDatabaseShort;
+ (void) dumpImageDirContents;
+ (void) dumpVideoDirContents; //jxi;

- (void) deleteData:(NSString *)tablename;

// Operations on user data object
- (int) numUserData;
- (TPUserData *) getUserData:(NSString *)userdata_id;
- (void) getUserDataList:(NSMutableArray *)userdata target:(int)target_id filterUserId:(int)filterUserId;
- (void) getImageList:(NSMutableArray *)userdata_list target:(int)target_id filterUserId:(int)filterUserId;
- (void) getVideoList:(NSMutableArray *)userdata_list target:(int)target_id filterUserId:(int)filterUserId; //jxi;

- (NSDictionary *) getTotalElapsedByUserId:(int)filterUserId;
- (NSDictionary *) getTotalFormsByUserId:(int)filterUserId;

- (void) getImageListByUserdataId:(NSMutableArray *)image_list userdataId:(NSString *)userdataId;

- (BOOL) imageDataDoesExist:(NSString *)userdataId imageType:(int)imageType;
- (BOOL) imageFileDoesExist:(NSString *)userdataId imageType:(int)imageType;

- (void) getVideoListByUserdataId:(NSMutableArray *)video_list userdataId:(NSString *)userdataId;

- (BOOL) videoDataDoesExist:(NSString *)userdataId; //jxi;
- (BOOL) videoFileDoesExist:(NSString *)userdataId; //jxi;

- (int) getRubricIdFromUserdataID:(NSString *)userdata_id;
- (BOOL) purgeUserDataIfEmpty:(NSString *)userdata_id;
- (int) countUserDataEntries:(NSString *)userdata_id;

- (void) updateUserData:(TPUserData *)userdata setModified:(BOOL)setModified;
- (void) updateImage:(TPImage *)image;
- (void) updateVideo:(TPVideo *)video; //jxi;
- (void) updateImageOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin;
- (void) updateVideoOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin; //jxi;
- (void) updateUserDataShare:(NSString *)userdata_id share:(int)newshare;
- (void) updateUserData:(NSString *)userdata_id name:(NSString *)newname share:(int)newshare description:(NSString *)newdescription;
- (int) getUserDataState:(NSString *)userdata_id;
- (void) updateUserDataState:(NSString *)userdata_id state:(int)newstate;
- (void) updateUserDataStateNoTimestamp:(NSString *)userdata_id state:(int)newstate;
- (void) updateUserDataElapsed:(NSString *)userdata_id elapsed:(int)newelapsed;
- (void) updateUserDataGrade:(NSString *)userdata_id grade:(int)newgrade;
- (void) deleteUserData:(NSString *)userdata_id includingImages:(BOOL)includingImages;

// Operations on rubric data
- (BOOL) ratingIsSelected:(TPRating *)rating question:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (float) ratingValue:(TPRating *)rating question:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (NSString *) questionText:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (NSString *) questionAnnot:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (NSDate *) questionDatevalue:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (void) deleteRubricData:(int)rubric_id;
- (void) deleteImage:(NSString *)userdata_id imageType:(int)imageType;
- (void) deleteVideo:(NSString *)userdata_id; //jxi;

// Operations used for syncing data
- (int) getUserDataUnsyncedCount;
//- (void) getUserDataUnsyncedDataList:(NSMutableArray *)userdata_queue localImagesList:(NSMutableArray *)local_images_queue includeCurrentUserdata:(BOOL)includeCurrentUserdata;
- (void) getUserDataUnsyncedDataList:(NSMutableArray *)userdata_queue
                     localImagesList:(NSMutableArray *)local_images_queue
                     localVideosList:(NSMutableArray *)local_videos_queue
              includeCurrentUserdata:(BOOL)includeCurrentUserdata;//jxi;
- (BOOL) tryRestoreImageData:(NSString *)userdataId;
- (BOOL) tryRestoreVideoData:(NSString *)userdataId; //jxi;
- (NSString *) getUserDataXMLEncoding:(NSString *)userdata_id;
- (NSString *) getUserDataListXMLEncoding;
- (NSString *) getLocalImageXMLEncoding:(NSString *)userdata_id;
- (NSString *) getLocalVideoInfoXMLEncoding:(NSString *)userdata_id; //jxi;
- (NSData *) getLocalVideoXMLEncoding:(NSString *)userdata_id; //jxi;

- (void) getRecRubricList:(NSMutableArray *)userDataIdArray targetId:(int)target_id;

// Savepoint operations
- (void) setSavepointWithName:(NSString*) savepointName;
- (void) releaseSavepointWithName:(NSString*) savepointName;
- (void) rollbackToSavepointWithName:(NSString*) savepointName;

// Utility operations
- (NSString *) getTimestamp;
- (NSDate *) dateFromCharStr:(char *)date_str;
- (NSString *) stringFromDate:(NSDate *)date;
+ (NSString *) imagePathWithUserdataID:(NSString *)userdata_id suffix:(NSString *)suffix imageType:(int)imageType;
+ (NSString *) videoPathWithUserdataID:(NSString *)userdata_id suffix:(NSString *)suffix; //jxi;

//jxi; methods for advanced userdata sync
- (NSString *) getUserDataListXMLEncodingForUserDataSync:(NSMutableString*) strUserIdList;

@end

// --------------------------------------------------------------------------------------
