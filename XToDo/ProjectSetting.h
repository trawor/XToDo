//
//  ProjectSetting
//  XToDo
//
//  Created by shuice on 2014-03-08.
//  Copyright (c) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface ProjectSetting : NSObject <NSCoding>
@property NSArray* includeDirs;
@property NSArray* excludeDirs;
+ (ProjectSetting*)defaultProjectSetting;
- (NSString*)firstIncludeDir;
@end