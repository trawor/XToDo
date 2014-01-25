//
//  XToDoWindowController.m
//  XToDo
//
//  Created by Travis on 13-12-6.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDoWindowController.h"
#import "XToDoModel.h"

//TODO: add pull to refresh http://www.oschina.net/p/itpulltorefreshscrollview




@implementation ToDoCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSImageView *iv=[[NSImageView alloc] initWithFrame:NSMakeRect(0, 10, 16, 16)];
        iv.image=[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"checkmark_off"]];
        [self addSubview:iv];
        
        NSTextField *titleField=[[NSTextField alloc] initWithFrame:NSMakeRect(20, 15, frame.size.width-20, 20)];
        titleField.font=[NSFont systemFontOfSize:14];
        [titleField setAutoresizingMask:NSViewWidthSizable];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:titleField];
        self.titleField=titleField;
        
        
        NSTextField *fileField=[[NSTextField alloc] initWithFrame:NSMakeRect(20, 0, frame.size.width-20, 15)];
        fileField.font=[NSFont systemFontOfSize:11];
        fileField.textColor=[NSColor darkGrayColor];
        [fileField setAutoresizingMask:NSViewWidthSizable];
        [[fileField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:fileField];
        self.fileField=fileField;
        
        
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        
        [fileField setBezeled:NO];
        [fileField setDrawsBackground:NO];
        [fileField setEditable:NO];
        [fileField setSelectable:NO];
        
    }
    return self;
}


@end


@interface XToDoWindowController ()<NSOutlineViewDataSource,NSOutlineViewDelegate>
@property (weak) IBOutlet NSOutlineView *listView;

@property(nonatomic,retain)NSMutableDictionary *data;

@end

@implementation XToDoWindowController
static NSArray *types=Nil;

+(void)initialize{
    //the todo type we will show
    types=@[@"TODO",@"FIXME",@"???",@"!!!"];
    
}
- (IBAction)openAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://weibo.com/trawor"]];
}

-(void)windowDidLoad{
    [super windowDidLoad];
    self.listView.indentationMarkerFollowsCell=NO;
    self.listView.indentationPerLevel=10.0;
    self.listView.allowsMultipleSelection=NO;

    self.window.level=NSFloatingWindowLevel;
    self.data=[NSMutableDictionary dictionaryWithCapacity:5];
}


-(void)setItems:(NSArray *)items{
    _items=items;
    
    for (NSString *type in types) {
        NSPredicate *pred=[NSPredicate predicateWithFormat:@"typeString = %@",type];
        NSArray *arr=[items filteredArrayUsingPredicate:pred];
        if (arr.count) {
            [self.data setObject:arr forKey:type];
        }else{
            [self.data removeObjectForKey:type];
        }
    }
    
   [self.listView reloadData];
}

-(IBAction)showOpenPanel:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];

    [panel beginSheetModalForWindow:[self window] completionHandler: (^(NSInteger result){
        if(result == NSOKButton) {
            NSArray *fileURLs = [panel URLs];
            self.projectPath=[[fileURLs objectAtIndex:0] path];
            [self refresh:sender];
            
        }
    })];
}

- (IBAction)refresh:(id)sender {
    if (self.projectPath==nil) {
        //show a dialog to select path
        
        [self showOpenPanel:sender];
        
        
        return;
    }
    
    //TODO: show refresh stat
    
    NSArray *items=[XToDoModel findItemsWithPath:self.projectPath];
    self.items=items;
}


-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item{
    if ([item isKindOfClass:[XToDoItem class]]) {
        return 35.0;
    }
    return 25;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(XToDoItem*)item {
    NSLog(@"Display %@",[item description]);
}


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(XToDoItem*)item {
    if (![item isKindOfClass:[XToDoItem class]]) {
        NSTableCellView *cellView= [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        cellView.textField.stringValue=(id)item;
        
        return cellView;
    } else {
        
        NSString *cellID=@"TodoCell";
        
        ToDoCellView *cellView =[outlineView makeViewWithIdentifier:cellID owner:self];
        
        if (cellView==nil) {
            cellView = [[ToDoCellView alloc] initWithFrame:NSMakeRect(0, 0, outlineView.bounds.size.width, 35)];
            
            cellView.identifier = cellID;
            
        }

        cellView.titleField.stringValue = item.content;
        cellView.fileField.stringValue = [item.filePath lastPathComponent];
        
        //TODO: update 'complate' stat image
        return cellView;
    }
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if (item==nil) {
        return types.count;
    }
    return [self.data[item] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    if (item==nil) {
        return types[index];
    }
    
    return [self.data[item] objectAtIndex:index];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if ([item isKindOfClass:[XToDoItem class]]) {
        return NO;
    }
    return YES;
}
- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
    NSOutlineView *outlineView=notification.object;
    
    NSInteger row=[outlineView selectedRow];
    
    XToDoItem *item = [outlineView itemAtRow:row];
    
    
    if ([item isKindOfClass:[XToDoItem class]]) {
        [XToDoModel openItem:item];
        
    }else{
        [outlineView deselectRow:row];
    }

}


@end
