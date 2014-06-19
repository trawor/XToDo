//
//  PathEditViewController
//  XToDo
//
//  Created by shuice on 2014-03-09.
//  Copyright (c) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>
typedef NS_ENUM(NSInteger, PathEditType) {
    PathEditTypeInclude,
    PathEditTypeExclude,
};

@interface PathEditViewController : NSViewController <NSTableViewDataSource>
- (id)initWithArray:(NSArray*)array;
@property NSMutableArray* array;
@property (assign) PathEditType pathEditType;
@end