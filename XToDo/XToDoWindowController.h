//
//  XToDoWindowController.h
//  XToDo
//
//  Created by Travis on 13-12-6.
//  Copyright (c) 2013 fir.im  All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ToDoCellView : NSTableCellView
@property (nonatomic, retain) NSImageView *fixedImageView;
@property (nonatomic, strong) NSTextField* titleField;
@property (nonatomic, strong) NSTextField* fileField;
@end

@interface XToDoWindowController : NSWindowController

@property (nonatomic, retain) NSArray* items;

- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName;

- (IBAction)refresh:(id)sender;
@end
