//
//  XToDoPreferencesWindowController.m
//  XToDo
//
//  Created by Georg Kaindl on 25/01/14.
//  Copyright (c) 2014 Plumn LLC. All rights reserved.
//

#import "XToDoPreferencesWindowController.h"


NSString* const kXToDoTextSizePrefsKey          = @"XToDo_TextSize";
NSString* const kXToDoTagsKey                   = @"XToDo_Tags";

static NSString* kXToDoItemDraggingType         = @"drag_XToDoItems";


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

- (instancetype)copyWithZone:(NSZone *)zone
{
    XToDoTagName* aCopy = [[XToDoTagName alloc] init];
    aCopy.tagName = self.tagName;
    
    return aCopy;
}

@end

@interface XToDoPreferencesWindowController ()

@property (weak) IBOutlet NSTableView* tagsView;
@property (weak) IBOutlet NSArrayController* tagsController;

@property () NSArray* tagNames;

@end

@implementation XToDoPreferencesWindowController

- (id)initWithWindow:(NSWindow *)window
{
    if (nil != (self = [super initWithWindow:window])) {
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs registerDefaults:@{
            kXToDoTextSizePrefsKey : @(0),
            kXToDoTagsKey : @[@"TODO", @"FIXME", @"???", @"!!!"]
        }];
        
        //[prefs setObject:@[@"TODO", @"FIXME", @"???", @"!!!"] forKey:kXToDoTagsKey];
        
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
    [self.tagsView registerForDraggedTypes:@[kXToDoItemDraggingType]];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([notification object] == self.window) {
        NSMutableArray* updatedTags = [NSMutableArray arrayWithCapacity:[self.tagNames count]];
                                       
        [self.tagNames enumerateObjectsUsingBlock:^(id anObj, NSUInteger anIdx, BOOL* stop) {
            [updatedTags insertObject:[anObj tagName]
                              atIndex:anIdx];
        }];
        
        [[NSUserDefaults standardUserDefaults] setObject:updatedTags
                                                  forKey:kXToDoTagsKey];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    BOOL success = NO;
    
    if ([rowIndexes count] > 0) {
        [pboard declareTypes:@[kXToDoItemDraggingType] owner:self];
        [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes]
                forType:kXToDoItemDraggingType];
        
        success = YES;
    }
    
    return success;
}

- (NSDragOperation)tableView:(NSTableView*)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return (NSTableViewDropOn != operation && nil != [[info draggingPasteboard] availableTypeFromArray:@[kXToDoItemDraggingType]]) ?
        NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
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

@end
