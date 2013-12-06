//
//  XToDoWindowController.m
//  XToDo
//
//  Created by Travis on 13-12-6.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDoWindowController.h"
#import "XToDoModel.h"

@interface XToDoWindowController ()<NSOutlineViewDataSource,NSOutlineViewDelegate>
@property (weak) IBOutlet NSOutlineView *listView;

@end

@implementation XToDoWindowController


- (void)windowDidLoad
{
    [super windowDidLoad];
    self.window.level=NSFloatingWindowLevel;
    [self refresh:nil];
}

-(void)setItems:(NSArray *)items{
    _items=items;
   [self.listView reloadData];
}

- (IBAction)refresh:(id)sender {
    if (self.projectPath==nil) {
        return;
    }
    NSArray *items=[XToDoModel findItemsWithPath:self.projectPath];
    self.items=items;
}



- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSLog(@"Display %@",[item description]);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    //NSLog(@"content %@",[item description]);
    return @"ok";
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (![item isKindOfClass:[XToDoItem class]]) {
        return [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
    } else {
        NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
        
        cellView.textField.stringValue = ((XToDoItem*)item).content;
        return cellView;
    }
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if (item==nil) {
        return self.items.count;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    if (item==nil && self.items.count>0) {
        XToDoItem *item=[self.items objectAtIndex:index];
        
        return item;
    }
    
    return nil;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if (item) {
        return NO;
    }
    return YES;
}


@end
