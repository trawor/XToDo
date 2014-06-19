//
//  XToDoPreferencesWindowController.m
//  XToDo
//
//  Created by Georg Kaindl on 25/01/14.
//  Copyright (c) 2014 Plumn LLC. All rights reserved.
//

#import "XToDoPreferencesWindowController.h"
#import "XToDoModel.h"
#import "PathEditViewController.h"

NSString* const kXToDoTextSizePrefsKey = @"XToDo_TextSize";
NSString* const kXToDoTagsKey = @"XToDo_Tags";
NSString* const kNotifyProjectSettingChanged = @"XToDo_NotifyProjectSettingChanged";

static NSString* kXToDoItemDraggingType = @"drag_XToDoItems";

@interface XToDoTagName : NSObject <NSCopying>
@property () NSString* tagName;
@end
@implementation XToDoTagName

- (instancetype)init
{
    if (nil != (self = [super init])) {
        self.tagName = @"New Tag";
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone*)zone
{
    XToDoTagName* aCopy = [[XToDoTagName alloc] init];
    aCopy.tagName = self.tagName;

    return aCopy;
}

@end

@interface XToDoPreferencesWindowController ()

@property (weak) IBOutlet NSTableView* tagsView;
@property (weak) IBOutlet NSArrayController* tagsController;
@property (weak) IBOutlet NSTextField* searchDirTextField;
@property (weak) IBOutlet NSTextField* excludeDirTextField;

@property () NSArray* tagNames;
- (IBAction)onTouchUpInsideEditInclude:(id)sender;
- (IBAction)onTouchUpInsideEditExclude:(id)sender;
@end

@implementation XToDoPreferencesWindowController

- (id)initWithWindow:(NSWindow*)window
{
    if (nil != (self = [super initWithWindow:window])) {
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        NSArray* tags = [prefs objectForKey:kXToDoTagsKey];
        NSMutableArray* tagNames = [[NSMutableArray alloc] initWithCapacity:[tags count]];
        for (NSString* aTag in tags) {
            XToDoTagName* aTagName = [[XToDoTagName alloc] init];
            aTagName.tagName = aTag;

            [tagNames addObject:aTagName];
        }
        self.tagNames = tagNames;
    }

    return self;
}

- (id)init
{
    return [self initWithWindowNibName:@"XToDoPreferencesWindowController"];
}

- (void)awakeFromNib
{
    [self.tagsView registerForDraggedTypes:@[ kXToDoItemDraggingType ]];
}

- (void)loadWindow
{
    [super loadWindow];
    [self _updateDirsUI];
}

- (void)windowWillClose:(NSNotification*)notification
{
    if ([notification object] == self.window) {
        NSMutableArray* updatedTags = [NSMutableArray arrayWithCapacity:[self.tagNames count]];

        [self.tagNames enumerateObjectsUsingBlock:^(id anObj, NSUInteger anIdx, BOOL* stop) {
            [updatedTags insertObject:[anObj tagName]
                              atIndex:anIdx];
        }];

        [[NSUserDefaults standardUserDefaults] setObject:updatedTags
                                                  forKey:kXToDoTagsKey];

        ProjectSetting* projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];
        [XToDoModel saveProjectSetting:projectSetting ByProjectName:self.projectName];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyProjectSettingChanged object:nil];
    }
}

- (BOOL)tableView:(NSTableView*)aTableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    BOOL success = NO;

    if ([rowIndexes count] > 0) {
        [pboard declareTypes:@[ kXToDoItemDraggingType ] owner:self];
        [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes]
                forType:kXToDoItemDraggingType];

        success = YES;
    }

    return success;
}

- (NSDragOperation)tableView:(NSTableView*)aTableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return (NSTableViewDropOn != operation && nil != [[info draggingPasteboard] availableTypeFromArray:@[ kXToDoItemDraggingType ]]) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    BOOL success = NO;
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:kXToDoItemDraggingType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

    if ([rowIndexes count] > 0) {
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger anIdx, BOOL* stop) {
            id anItem = [[self.tagsController arrangedObjects] objectAtIndex:anIdx];
            
            // since the table is configured to only allow selection/dragging of a single item, index conversion is trivial
            [self.tagsController removeObjectAtArrangedObjectIndex:anIdx];
            [self.tagsController insertObject:anItem atArrangedObjectIndex:(anIdx < row) ? row-1 : row];
        }];

        success = YES;
    }

    return success;
}

#pragma mark - Private
- (IBAction)onTouchUpInsideEditInclude:(id)sender
{
    ProjectSetting* projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    PathEditViewController* viewController = [[PathEditViewController alloc] initWithArray:projectSetting.includeDirs];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeInclude;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

- (IBAction)onTouchUpInsideEditExclude:(id)sender
{
    ProjectSetting* projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];
    NSPopover* popover = [[NSPopover alloc] init];
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    PathEditViewController* viewController = [[PathEditViewController alloc] initWithArray:projectSetting.excludeDirs];
    [popover setContentViewController:viewController];
    viewController.pathEditType = PathEditTypeExclude;
    [popover showRelativeToRect:CGRectMake(0, 0, 400, 400) ofView:sender preferredEdge:NSMinXEdge];
}

- (void)_updateDirsUI
{
    ProjectSetting* projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];

    NSArray* readableIncludePaths = [XToDoModel explandRootPathMacros:[projectSetting includeDirs]
                                                          projectPath:self.searchRootDir];
    self.searchDirTextField.stringValue = [readableIncludePaths componentsJoinedByString:@"    "];
    [self.searchDirTextField setSelectable:YES];
    [self.searchDirTextField setEditable:NO];
    [self.searchDirTextField resignFirstResponder];

    NSArray* readableExcludePaths = [XToDoModel explandRootPathMacros:[projectSetting excludeDirs]
                                                          projectPath:self.searchRootDir];
    self.excludeDirTextField.stringValue = [readableExcludePaths componentsJoinedByString:@"    "];
    [self.excludeDirTextField setSelectable:YES];
    [self.excludeDirTextField setEditable:NO];
    [self.excludeDirTextField resignFirstResponder];
}

#pragma mark - NSPopoverDelegate
- (void)popoverDidClose:(NSNotification*)notification
{
    NSPopover* popOver = [notification object];
    if ([popOver isKindOfClass:[NSPopover class]] == NO) {
        return;
    }

    PathEditViewController* pathEditViewController = (PathEditViewController*)[popOver contentViewController];
    if ([pathEditViewController isKindOfClass:[PathEditViewController class]] == NO) {
        return;
    }
    ProjectSetting* projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];
    if (pathEditViewController.pathEditType == PathEditTypeInclude) {
        projectSetting.includeDirs = [pathEditViewController array];
    } else if (pathEditViewController.pathEditType == PathEditTypeExclude) {
        projectSetting.excludeDirs = [pathEditViewController array];
    }
    [self _updateDirsUI];
}
@end
