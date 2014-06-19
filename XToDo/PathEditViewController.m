//
//  PathEditViewController
//  XToDo
//
//  Created by shuice on 2014-03-09.
//  Copyright (c) 2014. All rights reserved.
//

#import "PathEditViewController.h"
#import "XToDoModel.h"
#import "XToDo.h"
extern XToDo* sharedPlugin;

@interface PathEditViewController ()
@property IBOutlet NSTableView* tableView;
- (IBAction)onTouchUpInsideDelete:(id)sender;
- (IBAction)onTouchUpInsideInsert:(id)sender;
@end

@implementation PathEditViewController

#pragma mark - override
- (id)initWithArray:(NSArray*)array
{
    PathEditViewController* pathEditViewController = [self initWithNibName:@"PathEditViewController"
                                                                    bundle:sharedPlugin.bundle];
    self.array = [[NSMutableArray alloc] initWithArray:array copyItems:YES];
    return pathEditViewController;
}

- (void)awakeFromNib
{
    [self.tableView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
    [self.tableView setHeaderView:nil];
    self.tableView.dataSource = self;
    [self.tableView reloadData];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification
                                               object:nil];
}

- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private
- (IBAction)onTouchUpInsideDelete:(id)sender
{
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow == -1) {
        return;
    }
    [self.tableView beginUpdates];
    [self.array removeObjectAtIndex:selectedRow];
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedRow]
                          withAnimation:NSTableViewAnimationEffectNone];
    [self.tableView endUpdates];

    if ([self.array count] > 0) {
        if (selectedRow >= [self.array count]) {
            selectedRow = [self.array count] - 1;
        }
        NSIndexSet* selSet = [NSIndexSet indexSetWithIndex:selectedRow];
        [self.tableView selectRowIndexes:selSet byExtendingSelection:NO];
    }
}

- (IBAction)onTouchUpInsideInsert:(id)sender
{
    [self.tableView beginUpdates];
    [self.array addObject:[XToDoModel rootPathMacro]];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.tableView.numberOfRows]
                          withAnimation:NSTableViewAnimationEffectNone];
    [self.tableView endUpdates];
    [self.tableView editColumn:0 row:self.tableView.numberOfRows - 1 withEvent:nil select:YES];
}

#pragma mark - NSTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return [self.array count];
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
    return [self.array objectAtIndex:rowIndex];
}

#pragma mark - Notify
- (void)editingDidEnd:(NSNotification*)notification
{
    if ([notification object] != self.tableView) {
        return;
    }

    NSInteger row = [self.tableView editedRow];
    if ((row < 0) || (row >= [self.array count])) {
        return;
    }

    NSTextView* textView = [[notification userInfo] objectForKey:@"NSFieldEditor"];
    if ([textView isKindOfClass:[NSTextView class]] == NO) {
        return;
    }

    [self.array replaceObjectAtIndex:row withObject:[[textView string] copy]];
    [self.tableView reloadData];
}

@end
