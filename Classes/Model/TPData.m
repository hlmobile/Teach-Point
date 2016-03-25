#import "TPData.h"
#import "TPModel.h"
#import "TPUtil.h"
#import "TPDatabase.h"
#import <MediaPlayer/MediaPlayer.h>//jxi;

// ----------------------------------------------------------------------------------------------
// Data stored in NSEncoded files
// ----------------------------------------------------------------------------------------------
@implementation TPPublicState

@synthesize state;
@synthesize district_name;
@synthesize first_name;
@synthesize last_name;
@synthesize hashed_password;
@synthesize is_demo;

- (id)init {
	self = [ super init ];
	if (self != nil) {
		self.state = @"install";
        self.district_name = @"";
        self.first_name = @"";
        self.last_name = @"";
        self.hashed_password = @"";
        self.is_demo = 0;
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:state forKey:@"state"];
    [encoder encodeObject:district_name forKey:@"district_name"];
    [encoder encodeObject:first_name forKey:@"first_name"];
    [encoder encodeObject:last_name forKey:@"last_name"];
    [encoder encodeObject:hashed_password forKey:@"hashed_password"];
    [encoder encodeInteger:is_demo forKey:@"is_demo"];
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		self.state = [decoder decodeObjectForKey:@"state"];
        self.district_name = [decoder decodeObjectForKey:@"district_name"];
        self.first_name = [decoder decodeObjectForKey:@"first_name"];
        self.last_name = [decoder decodeObjectForKey:@"last_name"];
        self.hashed_password = [decoder decodeObjectForKey:@"hashed_password"];
        is_demo = [decoder decodeIntegerForKey:@"is_demo"];
	}
	return self;
}

- (void) dealloc {
    self.state = nil;
    self.district_name = nil;
    self.first_name = nil;
    self.last_name = nil;
    self.hashed_password = nil;
    [super dealloc];
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPAppState

@synthesize state;
@synthesize districtlogin;
@synthesize login;
@synthesize password;
@synthesize sync_status;
@synthesize sync_message;
@synthesize user_id;
@synthesize first_name;
@synthesize last_name;
@synthesize district_id;
@synthesize district_name;
@synthesize target_id;
@synthesize rubric_id;
@synthesize userdata_id;
@synthesize can_edit;
@synthesize last_sync;
@synthesize last_sync_completed;
@synthesize user_sort;
@synthesize lock;

- (id)init {
	self = [ super init ];
	if (self != nil) {
		self.state = @"install";
        self.districtlogin = @"";
		self.login = @"";
		self.password = @"";
		self.sync_status = @"";
		self.sync_message = @"";
        self.user_id = 0;
        self.first_name = @"";
        self.last_name = @"";
        self.district_id = 0;
        self.district_name = @"";
		self.target_id = 0;
		self.rubric_id = 0;
        self.userdata_id = @"";
        self.can_edit = 0;
        self.last_sync = nil;
        self.last_sync_completed = nil;
        self.user_sort = 0;
        self.lock = 0;
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:state forKey:@"state"];
    [encoder encodeObject:districtlogin forKey:@"districtlogin"];
	[encoder encodeObject:login forKey:@"login"];
	[encoder encodeObject:password forKey:@"password"];
	[encoder encodeObject:sync_status forKey:@"sync_status"];
	[encoder encodeObject:sync_message forKey:@"sync_message"];
    [encoder encodeInteger:user_id forKey:@"user_id"];
    [encoder encodeObject:first_name forKey:@"first_name"];
    [encoder encodeObject:last_name forKey:@"last_name"];
    [encoder encodeInteger:district_id forKey:@"district_id"];
    [encoder encodeObject:district_name forKey:@"district_name"];
	[encoder encodeInteger:target_id forKey:@"target_id"];
	[encoder encodeInteger:rubric_id forKey:@"rubric_id"];
    [encoder encodeObject:userdata_id forKey:@"userdata_id"];
    [encoder encodeInteger:can_edit forKey:@"can_edit"];
    [encoder encodeObject:last_sync forKey:@"last_sync"];
    [encoder encodeObject:last_sync_completed forKey:@"last_sync_completed"];
    [encoder encodeInteger:user_sort forKey:@"user_sort"];
    [encoder encodeInteger:lock forKey:@"lock"];
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		self.state = [decoder decodeObjectForKey:@"state"];
        self.districtlogin = [decoder decodeObjectForKey:@"districtlogin"];
		self.login = [decoder decodeObjectForKey:@"login"];
		self.password = [decoder decodeObjectForKey:@"password"];
		self.sync_status = [decoder decodeObjectForKey:@"sync_status"];
		self.sync_message = [decoder decodeObjectForKey:@"sync_message"];
        user_id = [decoder decodeIntegerForKey:@"user_id"];
        self.first_name = [decoder decodeObjectForKey:@"first_name"];
        self.last_name = [decoder decodeObjectForKey:@"last_name"];
        district_id = [decoder decodeIntegerForKey:@"district_id"];
        self.district_name = [decoder decodeObjectForKey:@"district_name"];
		target_id = [decoder decodeIntegerForKey:@"target_id"];
		rubric_id = [decoder decodeIntegerForKey:@"rubric_id"];
        self.userdata_id = [decoder decodeObjectForKey:@"userdata_id"];
        can_edit = [decoder decodeIntegerForKey:@"can_edit"];
        self.last_sync = [decoder decodeObjectForKey:@"last_sync"];
        self.last_sync_completed = [decoder decodeObjectForKey:@"last_sync_completed"];
        user_sort = [decoder decodeIntegerForKey:@"user_sort"];
        lock = [decoder decodeIntegerForKey:@"lock"];
	}
	return self;
}

- (void) dealloc {
    self.state = nil;
    self.districtlogin = nil;
    self.login = nil;
    self.password = nil;
    self.sync_status = nil;
    self.sync_message = nil;
    self.first_name = nil;
    self.last_name = nil;
    self.district_name = nil;
    self.userdata_id = nil;
    self.last_sync = nil;
    self.last_sync_completed = nil;
    [super dealloc];
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPUser

@synthesize user_id;
@synthesize type;
@synthesize permission;
@synthesize first_name;
@synthesize last_name;
@synthesize job_position;
@synthesize school_id;
@synthesize schools;
@synthesize grade_min;
@synthesize grade_max;
@synthesize subject_id;
@synthesize subjects;
@synthesize first_year;
@synthesize first_year_in_district;
@synthesize professional_status;
@synthesize employee_id;
@synthesize email;
@synthesize state;
@synthesize modified;
@synthesize total_forms;
@synthesize total_elapsed;

- (id)init {
	self = [ super init ];
	if (self != nil) {
		self.user_id = 0;
        self.type = 0;
        self.permission = TP_PERMISSION_UNKNOWN;
		self.first_name = @"";
		self.last_name = @"";
        self.job_position = @"";
        self.school_id = 0;
        self.schools = @"";
        self.grade_min = 0;
        self.grade_max = 0;
        self.subject_id = 0;
        self.subjects = @"";
		self.first_year = 0;
		self.first_year_in_district = 0;
		self.professional_status = @"";
        self.employee_id = @"";
        self.email = @"";
        self.state = 0;
        self.total_forms = 0;
        self.total_elapsed = 0;
        self.modified = nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:user_id forKey:@"user_id"];
    [encoder encodeInteger:type forKey:@"type"];
    [encoder encodeInteger:permission forKey:@"permission"];
	[encoder encodeObject:first_name forKey:@"first_name"];
	[encoder encodeObject:last_name forKey:@"last_name"];
    [encoder encodeObject:job_position forKey:@"job_position"];
    [encoder encodeInteger:school_id forKey:@"school_id"];
    [encoder encodeObject:schools forKey:@"schools"];
    [encoder encodeInteger:grade_min forKey:@"grade_min"];
    [encoder encodeInteger:grade_max forKey:@"grade_max"];
    [encoder encodeInteger:subject_id forKey:@"subject_id"];
    [encoder encodeObject:subjects forKey:@"subjects"];
	[encoder encodeInteger:first_year forKey:@"first_year"];
    [encoder encodeInteger:first_year_in_district forKey:@"first_year_in_district"];
	[encoder encodeObject:professional_status forKey:@"professional_status"];
	[encoder encodeObject:employee_id forKey:@"employee_id"];
    [encoder encodeObject:email forKey:@"email"];
    [encoder encodeInteger:state forKey:@"state"];
    [encoder encodeObject:modified forKey:@"modified"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		user_id = [decoder decodeIntegerForKey:@"user_id"];
        type = [decoder decodeIntegerForKey:@"type"];
        permission = [decoder decodeIntegerForKey:@"permission"];
		self.first_name = [decoder decodeObjectForKey:@"first_name"];
		self.last_name = [decoder decodeObjectForKey:@"last_name"];
        self.job_position = [decoder decodeObjectForKey:@"job_position"];
        school_id = [decoder decodeIntegerForKey:@"school_id"];
        self.schools = [decoder decodeObjectForKey:@"schools"];
        grade_min = [decoder decodeIntegerForKey:@"grade_min"];
        grade_max = [decoder decodeIntegerForKey:@"grade_max"];
        subject_id = [decoder decodeIntegerForKey:@"subject_id"];
        self.subjects = [decoder decodeObjectForKey:@"subjects"];
		first_year = [decoder decodeIntegerForKey:@"first_year"];
        first_year_in_district = [decoder decodeIntegerForKey:@"first_year_in_district"];
		self.professional_status = [decoder decodeObjectForKey:@"professional_status"];
		self.employee_id = [decoder decodeObjectForKey:@"employee_id"];
        self.email = [decoder decodeObjectForKey:@"email"];
        state = [decoder decodeIntegerForKey:@"state"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
	}
	return self;
}

- (void) dealloc {
    self.first_name = nil;
    self.last_name = nil;
    self.job_position = nil;
    self.schools = nil;
    self.subjects = nil;
    self.professional_status = nil;
    self.employee_id = nil;
    self.email = nil;
    self.modified = nil;
    [super dealloc];
}

- (NSComparisonResult) compareName:(TPUser *)user {
	int comp = [self.last_name compare:user.last_name options:NSCaseInsensitiveSearch];
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return [self.first_name compare:user.first_name options:NSCaseInsensitiveSearch];
	} else {
		return NSOrderedDescending;
	}
}

- (NSComparisonResult) compareSchool:(TPUser *)user {
	int comp = [self.schools compare:user.schools options:NSCaseInsensitiveSearch];
    if (comp == NSOrderedSame) {
        return [self compareName:user];
    } else {
        return comp;
    }
}

- (NSComparisonResult) compareGrade:(TPUser *)user {
    int comp = [TPUser getGradeAdjustedValue:self.grade_min] - [TPUser getGradeAdjustedValue:user.grade_min];
    if (comp == 0) {
        comp = [TPUser getGradeAdjustedValue:self.grade_max] - [TPUser getGradeAdjustedValue:user.grade_max];
        if (comp == 0) {
          return [self compareName:user];
        } else {
            return comp;
        }
    } else {
        return comp;
    }
}

- (NSString *) getDisplayName {
	return [NSString stringWithFormat:@"%@ %@", first_name, last_name];
}

- (NSString *) getGradeString {
    if (grade_min < 1 || grade_min > 15) {
        return @"";
    } else if (grade_min == grade_max) {
        return [NSString stringWithFormat:@"%@", [TPUser getGradeStringById:grade_min]];
    } else {
        return [NSString stringWithFormat:@"%@ - %@", [TPUser getGradeStringById:grade_min], [TPUser getGradeStringById:grade_max]];
    }
}

- (NSString *) getGradeStringShort {
    if (grade_min < 1 || grade_min > 15) {
        return @"";
    } else if (grade_min == grade_max) {
        return [NSString stringWithFormat:@"%@", [TPUser getGradeStringById:grade_min]];
    } else {
        return [NSString stringWithFormat:@"%@-%@", [TPUser getGradeStringById:grade_min], [TPUser getGradeStringById:grade_max]];
    }
}

- (NSString *) getGradePickerStringByIndex:(int)index {
    return [TPUser getGradeFullStringByAdjustedValue:[TPUser getGradeAdjustedValue:grade_min]+index];
}

- (int) getGradeIdByPickerIndex:(int)index {
    int gradeValue = [TPUser getGradeAdjustedValue:grade_min] + index;
    switch (gradeValue) {
        case 0:
            return 0;
        case 1:
            return 14;
        case 2:
            return 1;
        case 15:
            return 15;
        default:
            return gradeValue - 1;
    }
}

- (int) getGradeRangeSize {
    return [TPUser getGradeAdjustedValue:grade_max] - [TPUser getGradeAdjustedValue:grade_min] + 1;
}

+ (NSString *) getGradeStringById:(int)gradeId {
    return [TPUser getGradeStringByAdjustedValue:[TPUser getGradeAdjustedValue:gradeId]];
}

+ (NSString *) getGradeStringByAdjustedValue:(int)value {
	if (value < 1 || value > 15) {
        return @"";
    } else if (value == 1) {
        return @"PreK";
    } else if (value == 2) {
        return @"K";
    } else if (value == 15) {
        return @"12+";
    } else {
        return [NSString stringWithFormat:@"%d", value - 2];
	}
}

+ (NSString *) getGradeFullStringByAdjustedValue:(int)value {
	if (value < 1 || value > 15) {
        return @"";
    } else if (value == 1) {
        return @"PreK";
    } else if (value == 2) {
        return @"Kindergarten";
    } else if (value == 15) {
        return @"12+";
    } else {
        return [NSString stringWithFormat:@"%d", value - 2];
	}
}

+ (int) getGradeAdjustedValue:(int)gradeId {
    switch (gradeId) {
        case 0:
            return 0;
        case 14:
            return 1;
        case 15:
            return 15;
        default:
            return gradeId + 1;
    }
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPUserInfo

@synthesize user_id;
@synthesize type;
@synthesize info;
@synthesize modified;

- (id)init {
	self = [ super init ];
	if (self != nil) {
		self.user_id = 0;
        self.type = 0;
        self.info = @"";
        self.modified = nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:user_id forKey:@"user_id"];
    [encoder encodeInteger:type forKey:@"type"];
	[encoder encodeObject:info forKey:@"info"];
    [encoder encodeObject:modified forKey:@"modified"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		user_id = [decoder decodeIntegerForKey:@"user_id"];
        type = [decoder decodeIntegerForKey:@"type"];
        self.info = [decoder decodeObjectForKey:@"info"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
	}
	return self;
}

- (void) dealloc {
    self.info = nil;
    self.modified = nil;
    [super dealloc];
}

- (NSComparisonResult) compare:(TPUserInfo *)userinfo {
	int comp = self.user_id - userinfo.user_id;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPCategory

@synthesize category_id;
@synthesize name;
@synthesize corder;
@synthesize state;
@synthesize modified;

- (id)init {
	self = [ super init ];
	if (self != nil) {
		self.category_id = 0;
        self.name = @"";
        self.corder = 0;
        self.state = 0;
        self.modified = nil;
	}
	return self;
}

- (void) dealloc {
    self.name = nil;
    self.modified = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:category_id forKey:@"category_id"];
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeInteger:corder forKey:@"corder"];
    [encoder encodeInteger:state forKey:@"state"];
    [encoder encodeObject:modified forKey:@"modified"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		category_id = [decoder decodeIntegerForKey:@"category_id"];
        self.name = [decoder decodeObjectForKey:@"name"];
        corder = [decoder decodeIntegerForKey:@"corder"];
        state = [decoder decodeIntegerForKey:@"state"];
        self.modified = [decoder decodeObjectForKey:@"modified"];
	}
	return self;
}

- (NSComparisonResult) compare:(TPCategory *)category {
	int comp = self.corder - category.corder;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPRubric

@synthesize rubric_id;
@synthesize title;
@synthesize rec_stats;
@synthesize rec_elapsed;
@synthesize version;
@synthesize state;
@synthesize type;
@synthesize modified;
@synthesize rorder;
@synthesize group;

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:rubric_id forKey:@"rubric_id"];
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeInteger:rec_stats forKey:@"rec_stats"];
    [encoder encodeInteger:rec_elapsed forKey:@"rec_elapsed"];
    [encoder encodeInteger:version forKey:@"version"];
    [encoder encodeInteger:state forKey:@"state"];
    [encoder encodeInteger:type forKey:@"type"];
    [encoder encodeObject:modified forKey:@"modified"];
    [encoder encodeInteger:rorder forKey:@"rorder"];
    [encoder encodeObject:group forKey:@"rgroup"];
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		rubric_id = [decoder decodeIntegerForKey:@"rubric_id"];
        self.title = [decoder decodeObjectForKey:@"title"];
        rec_stats = [decoder decodeIntegerForKey:@"rec_stats"];
        rec_elapsed = [decoder decodeIntegerForKey:@"rec_elapsed"];
        version = [decoder decodeIntegerForKey:@"version"];
        state = [decoder decodeIntegerForKey:@"state"];
        self.modified = [decoder decodeObjectForKey:@"modified"];

        // migration from the bundle version 1.5 to 1.6: 
        if ([decoder containsValueForKey:@"type"]) {
            // type added
            type = [decoder decodeIntegerForKey:@"type"];
        } else {
            [self setType:0]; // default value
        }
        if ([decoder containsValueForKey:@"rorder"]) {
            rorder = [decoder decodeIntegerForKey:@"rorder"];
            self.group = [decoder decodeObjectForKey:@"rgroup"];
        } else {
            self.rorder = 0;
            self.group = @"";
        }
	}
	return self;
}

- (void) dealloc {
    self.title = nil;
    self.modified = nil;
    self.group = nil;
    [super dealloc];
}

- (NSComparisonResult) compare:(TPRubric *)rubric {
	int comp = self.rubric_id - rubric.rubric_id;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

- (NSComparisonResult) compareName:(TPRubric *)rubric {
    return [self.title compare:rubric.title options:NSCaseInsensitiveSearch];
}

- (NSComparisonResult) compareGroupName:(TPRubric *)rubric {
    return [self.group compare:rubric.group options:NSCaseInsensitiveSearch];
}

- (NSComparisonResult) compareOrder:(TPRubric *)rubric {
	int comp = self.rorder - rubric.rorder;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

- (NSComparisonResult) compareOrderThenName:(TPRubric *)rubric {
	int comp = self.rorder - rubric.rorder;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return [self compareName:rubric];
	} else {
		return NSOrderedDescending;
	}
}
    
-(BOOL) isRubricEditable {
    return (TP_RUBRIC_TYPE_READONLY == self.type) ? NO : YES;
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPQuestion

@synthesize question_id;
@synthesize rubric_id;
@synthesize order;
@synthesize type;
@synthesize subtype;
@synthesize category;
@synthesize optional;
@synthesize title;
@synthesize prompt;
@synthesize style;
@synthesize title_style;
@synthesize prompt_style;
@synthesize annotation;

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:question_id forKey:@"question_id"];
    [encoder encodeInteger:rubric_id forKey:@"rubric_id"];
    [encoder encodeInteger:order forKey:@"order"];
    [encoder encodeInteger:type forKey:@"type"];
    [encoder encodeInteger:subtype forKey:@"subtype"];
    [encoder encodeInteger:category forKey:@"category"];
    [encoder encodeInteger:optional forKey:@"optional"];
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeObject:prompt forKey:@"prompt"];
    
    [encoder encodeObject:[style objectForKey:@"font-size"] forKey:@"style-font-size"];
    [encoder encodeObject:[style objectForKey:@"background-color"] forKey:@"style-background-color"];
    [encoder encodeObject:[style objectForKey:@"text-align"] forKey:@"style-text-align"];

    [encoder encodeObject:[title_style objectForKey:@"font-size"] forKey:@"title-style-font-size"];
    [encoder encodeObject:[title_style objectForKey:@"background-color"] forKey:@"title-style-background-color"];
    [encoder encodeObject:[title_style objectForKey:@"text-align"] forKey:@"title-style-text-align"];
    
    [encoder encodeObject:[prompt_style objectForKey:@"font-size"] forKey:@"prompt-style-font-size"];
    [encoder encodeObject:[prompt_style objectForKey:@"background-color"] forKey:@"prompt-style-background-color"];
    [encoder encodeObject:[prompt_style objectForKey:@"text-align"] forKey:@"prompt-style-text-align"];
    
    [encoder encodeInteger:annotation forKey:@"annotation"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		question_id = [decoder decodeIntegerForKey:@"question_id"];
        rubric_id = [decoder decodeIntegerForKey:@"rubric_id"];
        order = [decoder decodeIntegerForKey:@"order"];
        type = [decoder decodeIntegerForKey:@"type"];
        
        // migration from the bundle version 1.5 to 1.6: 
        if ([decoder containsValueForKey:@"reflection"]) {
            // reflection replaced with subtype
            int reflection = [decoder decodeIntegerForKey:@"reflection"];
            [self setSubtype:reflection];
            // questions of type=8 now replaced with type/subtype=7/2
            if (8 == self.type) {
                [self setType:7];
                [self setSubtype:2];
            }
            // questions of type=11 now replaced with type/subtype=2/2
            if (11 == self.type) {
                [self setType:2];
                [self setSubtype:2];
            }
        } else {
            subtype = [decoder decodeIntegerForKey:@"subtype"];
        }

        category = [decoder decodeIntegerForKey:@"category"];
        optional = [decoder decodeIntegerForKey:@"optional"];
        self.title = [decoder decodeObjectForKey:@"title"];
        self.prompt = [decoder decodeObjectForKey:@"prompt"];
        
        NSObject *foundObject;
        
        style  = [[NSMutableDictionary alloc] init];
        foundObject = [decoder decodeObjectForKey:@"style-font-size"];
        if (foundObject != nil) [style setObject:foundObject forKey:@"font-size"];
        foundObject = [decoder decodeObjectForKey:@"style-background-color"];
        if (foundObject != nil) [style setObject:foundObject forKey:@"background-color"];
        foundObject = [decoder decodeObjectForKey:@"style-text-align"];
        if (foundObject != nil) [style setObject:foundObject forKey:@"text-align"];
        
        title_style = [[NSMutableDictionary alloc] init];
        foundObject = [decoder decodeObjectForKey:@"title-style-font-size"];
        if (foundObject != nil) [title_style setObject:foundObject forKey:@"font-size"];
        foundObject = [decoder decodeObjectForKey:@"title-style-background-color"];
        if (foundObject != nil) [title_style setObject:foundObject forKey:@"background-color"];
        foundObject = [decoder decodeObjectForKey:@"title-style-text-align"];
        if (foundObject != nil) [title_style setObject:foundObject forKey:@"text-align"];
        
        prompt_style = [[NSMutableDictionary alloc] init];
        foundObject = [decoder decodeObjectForKey:@"prompt-style-font-size"];
        if (foundObject != nil) [prompt_style setObject:foundObject forKey:@"font-size"];
        foundObject = [decoder decodeObjectForKey:@"prompt-style-background-color"];
        if (foundObject != nil) [prompt_style setObject:foundObject forKey:@"background-color"];
        foundObject = [decoder decodeObjectForKey:@"prompt-style-text-align"];
        if (foundObject != nil) [prompt_style setObject:foundObject forKey:@"text-align"];
        
        annotation = [decoder decodeIntegerForKey:@"annotation"];
        
        int xrecari = 0;
        xrecari++;
	}
	return self;
}

-(void) dealloc {
    self.title = nil;
    self.prompt = nil;
	[style release];
    [title_style release];
    [prompt_style release];
	[super dealloc];
}

- (NSComparisonResult) compare:(TPQuestion *)question {
	int comp = self.order - question.order;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

+ (NSMutableDictionary *) styleWithString: (NSString *) string {
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *outdict = [[[NSMutableDictionary alloc] init] autorelease];
    
    NSCharacterSet *keyEndSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSCharacterSet *valueEndSet = [NSCharacterSet characterSetWithCharactersInString:@";"];
    
    while (![scanner isAtEnd]) {
        NSString *key;
        NSString *value;
        
        [scanner scanUpToCharactersFromSet:keyEndSet intoString:&key];
        [scanner scanCharactersFromSet:keyEndSet intoString:NULL];
        [scanner scanUpToCharactersFromSet:valueEndSet intoString:&value];
        [scanner scanCharactersFromSet:valueEndSet intoString:NULL];
        
        [dict setValue:value forKey:key];
    }
    [scanner release];
    
    for (NSString *key in dict) {
        NSString *value = (NSString *)[dict objectForKey:key];
        if ([key isEqualToString:@"font-size"]) {
            NSArray *fontSizeValue = [value componentsSeparatedByString:@"px"];
            float fontSize = (CGFloat)[(NSString *)[fontSizeValue objectAtIndex:0] floatValue];
            [outdict setObject:[NSNumber numberWithFloat:fontSize] forKey:key];
        } else if ([key isEqualToString:@"background-color"]) {
            [outdict setObject:value forKey:key];
        } else if ([key isEqualToString:@"text-align"]) {
            [outdict setObject:value forKey:key];
        }
    }
    
    if (dict) {
        int i =0;
        i++;
    }
    
    [dict release];
    
    return outdict;
}

-(BOOL) isQuestionEditable {
    return (TP_QUESTION_SUBTYPE_READONLY == self.subtype || TP_QUESTION_SUBTYPE_COMPUTED == self.subtype) ? NO : YES;
}

-(BOOL) isQuestionReflection {
    return (TP_QUESTION_SUBTYPE_REFLECTION == self.subtype) ? YES : NO;
}

-(BOOL) isQuestionThirdparty {
    return (TP_QUESTION_SUBTYPE_THIRDPARTY == self.subtype) ? YES : NO;
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPRating

@synthesize rating_id;
@synthesize question_id;
@synthesize rubric_id;
@synthesize rorder;
@synthesize value;
@synthesize text;
@synthesize title;

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInteger:rating_id forKey:@"rating_id"];
    [encoder encodeInteger:question_id forKey:@"question_id"];
    [encoder encodeInteger:rubric_id forKey:@"rubric_id"];
    [encoder encodeInteger:rorder forKey:@"rorder"];
    [encoder encodeFloat:value forKey:@"value"];
    [encoder encodeObject:text forKey:@"text"];
    [encoder encodeObject:title forKey:@"title"];
}
- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		rating_id = [decoder decodeIntegerForKey:@"rating_id"];
        question_id = [decoder decodeIntegerForKey:@"question_id"];
        rubric_id = [decoder decodeIntegerForKey:@"rubric_id"];
        rorder = [decoder decodeIntegerForKey:@"rorder"];
        value = [decoder decodeFloatForKey:@"value"];
        self.text = [decoder decodeObjectForKey:@"text"];
        self.title = [decoder decodeObjectForKey:@"title"];
	}
	return self;
}

- (void) dealloc {
    self.text = nil;
    self.title = nil;
    [super dealloc];
}

- (NSComparisonResult) compare:(TPRating *)rating {
	int comp = self.rorder - rating.rorder;
	if (comp < 0) {
		return NSOrderedAscending;
	} else if (comp == 0) {
		return NSOrderedSame;
	} else {
		return NSOrderedDescending;
	}
}

+ (NSString *) getDefaultRatingScaleTitle:(int)order {
    switch (order) {
		case 1:
            return @"Exemplary";
		case 2:
			return @"Proficient";
		case 3:
			return @"Needs improvement";
		case 4:
			return @"Unsatisfactory";
		default:
			return @"";
	}
}

@end

// ----------------------------------------------------------------------------------------------
// Data stored in SQLite database
// ----------------------------------------------------------------------------------------------
@implementation TPUserData

@synthesize district_id;
@synthesize user_id;
@synthesize target_id;
@synthesize share;
@synthesize school_id;
@synthesize subject_id;
@synthesize grade;
@synthesize elapsed;
@synthesize type;
@synthesize rubric_id;
@synthesize name;
@synthesize userdata_id;
@synthesize state;
@synthesize created;
@synthesize modified;
@synthesize rubricdata;
@synthesize description;
@synthesize aud_id; //jxi
@synthesize aq_id; //jxi

+ (NSString *)generateUserdataIDWithModel:(TPModel *)aModel creationDate:(NSDate *)aDate type:(int)aType {

    NSString *created_str = [aModel.database stringFromDate:aDate];
    NSString *new_userdata_id = [NSString stringWithFormat:@"%d.%d.%d.%d.%@.%@.%d",
                             aModel.appstate.district_id, 
                             aModel.appstate.user_id, 
                             aModel.appstate.target_id, 
                             aType, 
                             [created_str substringToIndex:10],
                             [created_str substringFromIndex:11], 
                             (int)(random() * 1.0 / RAND_MAX * 999999999)];
    
    return new_userdata_id;
}

- (id) init {
	    
	self = [super init];
	if (self != nil) {
		district_id = 0;
		user_id = 0;
        target_id = 0;
        share = 0;
        school_id = 0;
        subject_id = 0;
        grade = 0;
        elapsed = 0;
        type = TP_USERDATA_TYPE_UNDEFINED;
        rubric_id = 0;
        self.name = @"";
        self.userdata_id = nil;
        state = 1;
        self.created = nil;
		self.modified = nil;
        rubricdata = [[NSMutableArray alloc] init];
        self.description = @"";
        aud_id = @""; //jxi
        aq_id = 0; //jxi
	}
	return self;
}

- (id) initWithModel:(TPModel *)model
                name:(NSString *)somename
            rubricId:(int)rubricId
                type:(int)sometype {
	    
	self = [super init];
	if (self != nil) {
        
        TPUser *user = [model getCurrentTarget];
        
		district_id = model.appstate.district_id;
		user_id = model.appstate.user_id;
        target_id = model.appstate.target_id;
        share = 0;
        school_id = user.school_id;
        subject_id = user.subject_id;
        grade = user.grade_min;
        elapsed = 0;
		type = sometype;
        rubric_id = rubricId;
        self.name = somename;
        self.created = [NSDate date];
        NSString *created_str = [model.database stringFromDate:created];
        self.userdata_id = [NSString stringWithFormat:@"%d.%d.%d.%d.%@.%@.%d",
                            district_id, user_id, target_id, type, [created_str substringToIndex:10],
                            [created_str substringFromIndex:11], (int)(random() * 1.0 / RAND_MAX * 999999999)];
        state = 1;
		self.modified = nil;
        rubricdata  = [[NSMutableArray alloc] init];
        self.description = @"";
	}
	return self;
}

/*
- (id) initWithModel:(TPModel *)aModel
          userdataID:(NSString *)aUserdataID
                name:(NSString *)aName
               share:(int)aShare
         description:(NSString *)aDescription
        creationDate:(NSDate *)aDate {
    
    self = [super init];
    if (self != nil) {
        district_id = aModel.appstate.district_id;
		user_id = aModel.appstate.user_id;
        target_id = aModel.appstate.target_id;

        share = aShare;
        self.name = aName;
		self.created = aDate;
        self.modified = aDate;
        self.userdata_id = aUserdataID;
        
        type = TP_USERDATA_TYPE_IMAGE;
        state = 3;

        school_id = 0;
        subject_id = 0;
        grade = 0;
        elapsed = 0;
		rubric_id = 0;

        rubricdata = [[NSMutableArray alloc] init];
        self.description = aDescription;

    }
    return self;
}
 */

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (id) initWithModel:(TPModel *)aModel
          userdataID:(NSString *)aUserdataID
                name:(NSString *)aName
               share:(int)aShare
         description:(NSString *)aDescription
        creationDate:(NSDate *)aDate type:(int)aType {
    
    self = [super init];
    if (self != nil) {
        district_id = aModel.appstate.district_id;
		user_id = aModel.appstate.user_id;
        target_id = aModel.appstate.target_id;
        
        share = aShare;
        self.name = aName;
		self.created = aDate;
        self.modified = aDate;
        self.userdata_id = aUserdataID;
        
        type = aType;
        state = 3;
        
        school_id = 0;
        subject_id = 0;
        grade = 0;
        elapsed = 0;
		rubric_id = 0;
        
        rubricdata = [[NSMutableArray alloc] init];
        self.description = aDescription;
        
    }
    return self;
}

- (id) initWithModel:(TPModel *)aModel
          userdataID:(NSString *)aUserdataID
                name:(NSString *)aName
               share:(int)aShare
         description:(NSString *)aDescription
        creationDate:(NSDate *)aDate type:(int)aType
             aAud_id:(NSString *)aAud_id aAq_id:(int)aAq_id {
 
    self = [super init];
    if (self != nil) {
        district_id = aModel.appstate.district_id;
		user_id = aModel.appstate.user_id;
        target_id = aModel.appstate.target_id;
        
        share = aShare;
        self.name = aName;
		self.created = aDate;
        self.modified = aDate;
        self.userdata_id = aUserdataID;
        
        type = aType;
        state = 3;
        
        school_id = 0;
        subject_id = 0;
        grade = 0;
        elapsed = 0;
		rubric_id = 0;
        
        rubricdata = [[NSMutableArray alloc] init];
        self.description = aDescription;
        
        self.aud_id = aAud_id;
        aq_id = aAq_id;
    }
    return self;
}

- (id) initWithUserData:(TPUserData *)userdata {
    
    self = [super init];
	if (self != nil) {
        district_id = userdata.district_id;
        user_id = userdata.user_id;
        target_id = userdata.target_id;
        share = userdata.share;
        school_id = userdata.school_id;
        subject_id = userdata.subject_id;
        grade = userdata.grade;
        elapsed = userdata.elapsed;
        type = userdata.type;
        rubric_id = userdata.rubric_id;
        self.name = userdata.name;
        self.userdata_id = userdata.userdata_id;
        state = userdata.state;
        self.created = userdata.created;
        self.modified = userdata.modified;
        if ([userdata.rubricdata count]) {
            rubricdata = [[NSMutableArray alloc] initWithArray:userdata.rubricdata];
        } else {
            rubricdata = [[NSMutableArray alloc] init];
        }
        self.description = userdata.description;
        self.aud_id = userdata.aud_id; //jxi
        aq_id = userdata.aq_id; //jxi
    }
    return self;
}

-(void) dealloc {
    self.name = nil;
    self.userdata_id = nil;
    self.created = nil;
    self.modified = nil;
    self.description = nil;
    self.aud_id=nil;//jxi
	[rubricdata release];
	[super dealloc];
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPRubricData

@synthesize district_id;
@synthesize userdata_id;
@synthesize rubric_id;
@synthesize question_id;
@synthesize rating_id;
@synthesize value;
@synthesize text;
@synthesize annotation;
@synthesize user;
@synthesize modified;
@synthesize datevalue;

- (id) initWithModel:(TPModel *)model rating:(TPRating *)rating {
    self = [super init];
    if (self != nil) {
        district_id = model.appstate.district_id;
        self.userdata_id = model.appstate.userdata_id;
        rubric_id = model.appstate.rubric_id;
        question_id = rating.question_id;
        rating_id = rating.rating_id;
        value = rating.value;
        self.text = rating.text;
        annotation = 0;
        user = model.appstate.user_id;
        self.modified = nil;
        self.datevalue = nil;
    }
    return self;
}

- (id) initWithModel:(TPModel *)model question:(TPQuestion *)question text:(NSString *)sometext {
    self = [super init];
    if (self != nil) {
        district_id = model.appstate.district_id;
        self.userdata_id = model.appstate.userdata_id;
        rubric_id = model.appstate.rubric_id;
        question_id = question.question_id;
        rating_id = 0;
        value = 0;
        self.text = sometext;
        annotation = 0;
        user = model.appstate.user_id;
        self.modified = nil;
        self.datevalue = nil;
    }
    return self;
}

- (id) initWithModel:(TPModel *)model question:(TPQuestion *)question text:(NSString *)sometext annotation:(int)annot
{
    self = [super init];
    if (self != nil) {
        district_id = model.appstate.district_id;
        self.userdata_id = model.appstate.userdata_id;
        rubric_id = model.appstate.rubric_id;
        question_id = question.question_id;
        rating_id = 0;
        value = 0;
        self.text = sometext;
        annotation = annot;
        user = model.appstate.user_id;
        self.modified = nil;
        self.datevalue = nil;
    }
    return self;
}

- (void) dealloc {
    self.userdata_id = nil;
    self.text = nil;
    self.modified = nil;
    self.datevalue = nil;
    [super dealloc];
}

@end

// ----------------------------------------------------------------------------------------------
@implementation TPImage

@synthesize district_id;
@synthesize userdata_id;
@synthesize type;
@synthesize width;
@synthesize height;
@synthesize format;
@synthesize encoding; 
@synthesize user_id;
@synthesize modified;
@synthesize image;
@synthesize filename;
@synthesize origin;

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
              origin:(int)originVal {
    // designated initializer
    self = [super init];
    if (self) {
        district_id = districtId;
        self.userdata_id = userdataId;
        type = typeVal;
        width = widthVal;
        height = heightVal;
        self.format = formatVal;
        self.encoding = encodingVal;
        user_id = userId;
        self.modified = modifiedDate;
        self.image = someimage;
        self.filename = fileName;
        origin = originVal;
    }    
    return self;
}

- (void)dealloc {
    self.userdata_id = nil;
    self.format = nil;
    self.encoding = nil;
    self.modified = nil;
    self.image = nil;
    self.filename = nil;
    [super dealloc];
}

- (UIImage *)createThumbnailImage {
    UIImage *thumbnail = nil;
    int thumbnail_width;
    int thumbnail_height;
    if (self.image.size.width / self.image.size.height >= 107.0 / 80.0) {
        thumbnail_width = 107;
        thumbnail_height = self.image.size.height * (107 / self.image.size.width);
    } else {
        thumbnail_height = 80;
        thumbnail_width = self.image.size.width * (80 / self.image.size.height);
    }
    if (debugData) NSLog(@"TPImage createThumbnailImage %d %d to %d %d", (int)(self.image.size.width), (int)(self.image.size.height), thumbnail_width, thumbnail_height);
    if (self.image) {
        thumbnail = [TPUtil thumbnailFromImage:self.image scaledToSize:CGSizeMake(thumbnail_width, thumbnail_height)]; 
    }
    return thumbnail;
}

- (BOOL)isPortraitImage {
    if (self.image.size.width >= self.image.size.height) {
        return NO;
    } else {
        return YES;
    }
}

- (NSComparisonResult) compareModifiedDate:(TPImage *)someimage {
    return [self.modified compare:someimage.modified];
}

@end

// ----------------------------------------------------------------------------------------------


//jxi;
@implementation TPVideo

@synthesize district_id;
@synthesize userdata_id;
@synthesize type;
@synthesize width;
@synthesize height;
@synthesize format;
@synthesize encoding;
@synthesize user_id;
@synthesize modified;
@synthesize videoUrl;
@synthesize filename;
@synthesize thumbImage;
@synthesize origin;

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
              origin:(int)originVal {
    // designated initializer
    self = [super init];
    if (self) {
        district_id = districtId;
        self.userdata_id = userdataId;
        type = typeVal;
        width = widthVal;
        height = heightVal;
        self.format = formatVal;
        self.encoding = encodingVal;
        user_id = userId;
        self.modified = modifiedDate;
        self.videoUrl = someVideo;
        self.filename = fileName;
        origin = originVal;
        [self createThumbnailImage];
    }
    return self;
}

- (void)dealloc {
    self.userdata_id = nil;
    self.format = nil;
    self.encoding = nil;
    self.modified = nil;
    self.videoUrl = nil;
    self.filename = nil;
    [super dealloc];
}


- (UIImage *)thumbnailImage {
    return self.thumbImage;
}

- (UIImage *)createThumbnailImage {
    int thumbnail_width;
    int thumbnail_height;
    UIImage *thumb;
    /*----------------------------------------*/
    NSURL *videoURL = [NSURL fileURLWithPath:self.filename];//self.videoUrl;
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    
    UIImage *newImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    //Player autoplays audio on init
    [player stop];
    [player release];
    
    
    if (newImage.size.width / newImage.size.height >= 107.0 / 80.0) {
        thumbnail_width = 107;
        thumbnail_height = newImage.size.height * (107 / newImage.size.width);
    } else {
        thumbnail_height = 80;
        thumbnail_width = newImage.size.width * (80 / newImage.size.height);
    }
    if (debugData) NSLog(@"TPImage createThumbnailImage %d %d to %d %d", (int)(newImage.size.width), (int)(newImage.size.height), thumbnail_width, thumbnail_height);
    if (newImage) {
        thumb = [TPUtil thumbnailFromImage:newImage scaledToSize:CGSizeMake(thumbnail_width, thumbnail_height)];
    }
    return thumb;
}

- (BOOL)isPortraitImage {
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:self.videoUrl];
    
    UIImage *newImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    //Player autoplays audio on init
    [player stop];
    [player release];
    
    if (newImage.size.width >= newImage.size.height) {
        return NO;
    } else {
        return YES;
    }
}

- (NSComparisonResult) compareModifiedDate:(TPVideo*)someimage {
    return [self.modified compare:someimage.modified];
}

@end
