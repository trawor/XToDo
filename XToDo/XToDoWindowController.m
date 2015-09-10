//
//  XToDoWindowController.m
//  XToDo
//
//  Created by Travis on 13-12-6.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDoWindowController.h"
#import "XToDoModel.h"
#import "XToDo.h"
#import "ProjectSetting.h"

#import "XToDoPreferencesWindowController.h"

//TODO: add pull to refresh http://www.oschina.net/p/itpulltorefreshscrollview

@implementation ToDoCellView

static NSImage *statusImageFixed;
static NSImage *statusImageTodo;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		if (!statusImageFixed) {
			statusImageFixed = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"checkmark_on"]];
		}
		if (!statusImageTodo) {
			statusImageTodo = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"checkmark_off"]];
		}
		
        XToDoTextSize textSize = [[NSUserDefaults standardUserDefaults] integerForKey:kXToDoTextSizePrefsKey];
        NSUInteger fontSize = 14, smallFontsize = 11;

        switch (textSize) {
        case kXToDoTextSizeLarge:
            fontSize = 14;
            smallFontsize = 11;
            break;
        case kXToDoTextSizeSmall:
            fontSize = 11;
            smallFontsize = 10;
            break;
        default:
            break;
        }

        self.fixedImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 10, 16, 16)];
		self.fixedImageView.image = statusImageTodo;
        [self addSubview:self.fixedImageView];

        self.titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 15, frame.size.width - 20, 20 - (14 - fontSize))];
        self.titleField.font = [NSFont systemFontOfSize:fontSize];
        [self.titleField setAutoresizingMask:NSViewWidthSizable];
        [[self.titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:self.titleField];
        self.titleField = self.titleField;

        self.fileField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 0, frame.size.width - 20, 15 + (11 - smallFontsize))];
        self.fileField.font = [NSFont systemFontOfSize:smallFontsize];
        self.fileField.textColor = [NSColor darkGrayColor];
        [self.fileField setAutoresizingMask:NSViewWidthSizable];
        [[self.fileField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:self.fileField];
        self.fileField = self.fileField;

        [self.titleField setBezeled:NO];
        [self.titleField setDrawsBackground:NO];
        [self.titleField setEditable:NO];
        [self.titleField setSelectable:NO];

        [self.fileField setBezeled:NO];
        [self.fileField setDrawsBackground:NO];
        [self.fileField setEditable:NO];
        [self.fileField setSelectable:NO];
    }
    return self;
}

- (void)setFixed:(BOOL)fixed {
	self.fixedImageView.image = fixed ? statusImageFixed : statusImageTodo;
}

@end

@interface XToDoWindowController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (weak) IBOutlet NSOutlineView* listView;
@property (weak) IBOutlet NSProgressIndicator* workingIndicator;
@property () NSArray* types;
@property () XToDoPreferencesWindowController* prefsController;
@property (nonatomic, copy) NSString* projectPath;
@property (nonatomic, copy) NSString* projectName;

@property (nonatomic, retain) NSMutableDictionary* data;

- (IBAction)showPreferencesPanel:(id)sender;

@end

@implementation XToDoWindowController

- (IBAction)openAbout:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://weibo.com/trawor"]];
}

- (void)awakeFromNib
{
    self.prefsController = [[XToDoPreferencesWindowController alloc] init];

    self.types = [[NSUserDefaults standardUserDefaults] objectForKey:kXToDoTagsKey];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.listView.indentationMarkerFollowsCell = NO;
    self.listView.indentationPerLevel = 10.0;
    self.listView.allowsMultipleSelection = NO;

    [self.workingIndicator setHidden:YES];

    self.window.level = NSFloatingWindowLevel;
	self.window.hidesOnDeactivate = YES;
    self.data = [NSMutableDictionary dictionaryWithCapacity:5];

    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

    [prefs addObserver:self
            forKeyPath:kXToDoTextSizePrefsKey
               options:NSKeyValueObservingOptionNew
               context:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_onNotifyProjectSettingChanged:)
                                                 name:kNotifyProjectSettingChanged
                                               object:nil];
}

- (void)dealloc
{
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

    [prefs removeObserver:self
               forKeyPath:kXToDoTextSizePrefsKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == [NSUserDefaults standardUserDefaults]) {
        if ([keyPath isEqualToString:kXToDoTextSizePrefsKey]) {
            [self.listView reloadData];
        }
    }
}

- (void)_onNotifyProjectSettingChanged:(NSNotification*)notification
{
    self.types = [[NSUserDefaults standardUserDefaults] objectForKey:kXToDoTagsKey];
    [self refresh:nil];
}

- (void)setItems:(NSArray*)items
{
    _items = items;

    for (NSString* type in self.types) {
        NSPredicate* pred = [NSPredicate predicateWithFormat:@"typeString = %@", type];
        NSArray* arr = [items filteredArrayUsingPredicate:pred];
        if (arr.count) {
            [self.data setObject:arr forKey:type];
        } else {
            [self.data removeObjectForKey:type];
        }
    }

    [self.listView reloadData];
}

- (IBAction)showOpenPanel:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];

    [panel beginSheetModalForWindow:[self window] completionHandler:(^(NSInteger result) {
        if(result == NSOKButton) {
            NSArray *fileURLs = [panel URLs];
            [self setSearchRootDir:[[fileURLs objectAtIndex:0] path] projectName:@"Test.xcodeproj"];
            [self refresh:sender];
            
        }
                                                                    })];
}

- (IBAction)refresh:(id)sender
{
    if (self.projectPath == nil) {
        //show a dialog to select path

        [self showOpenPanel:sender];

        return;
    }

    [self.workingIndicator setHidden:NO];
    [self.workingIndicator startAnimation:nil];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ProjectSetting *projectSetting = [XToDoModel projectSettingByProjectName:self.projectName];
        NSArray *items = [XToDoModel findItemsWithProjectSetting:projectSetting
                                                     projectPath:self.projectPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.items=items;
            [self.workingIndicator setHidden:YES];
            [self.workingIndicator stopAnimation:nil];
        });
    });
}
- (IBAction)showPreferencesPanel:(id)sender
{
    [self.prefsController loadWindow];

    NSRect windowFrame = [[self window] frame], prefsFrame = [[self.prefsController window] frame];
    prefsFrame.origin = NSMakePoint(windowFrame.origin.x + (windowFrame.size.width - prefsFrame.size.width) / 2.0,
                                    NSMaxY(windowFrame) - NSHeight(prefsFrame) - 20.0);

    [[self.prefsController window] setFrame:prefsFrame
                                    display:NO];

    [self.prefsController showWindow:sender];
}

- (void)setSearchRootDir:(NSString*)searchRootDir projectName:(NSString*)projectName
{
    //ProjectSetting *projectSetting = [XToDoModel projectSettingByProjectName:projectName];

    self.projectPath = searchRootDir;
    self.projectName = projectName;
    self.prefsController.projectName = projectName;
    self.prefsController.searchRootDir = searchRootDir;
}

- (CGFloat)outlineView:(NSOutlineView*)outlineView heightOfRowByItem:(id)item
{
    if ([item isKindOfClass:[XToDoItem class]]) {
        return 35.0;
    }
    return 25;
}

- (void)outlineView:(NSOutlineView*)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn item:(XToDoItem*)item
{
    //NSLog(@"Display %@",[item description]);
}

- (NSView*)outlineView:(NSOutlineView*)outlineView viewForTableColumn:(NSTableColumn*)tableColumn item:(XToDoItem*)item
{
    if (![item isKindOfClass:[XToDoItem class]]) {
        NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@ (%ld)", (id)item, [self.data[item] count]];

        return cellView;
    } else {

        NSString* cellID = [NSString stringWithFormat:@"TodoCell_%@", [[NSUserDefaults standardUserDefaults] objectForKey:kXToDoTextSizePrefsKey]];

        ToDoCellView* cellView = [outlineView makeViewWithIdentifier:cellID owner:self];

        if (cellView == nil) {
            cellView = [[ToDoCellView alloc] initWithFrame:NSMakeRect(0, 0, outlineView.bounds.size.width, 35)];

            cellView.identifier = cellID;
        }

        cellView.titleField.stringValue = item.content;
        cellView.fileField.stringValue = [[item.filePath lastPathComponent] stringByAppendingFormat:@":%ld",item.lineNumber];
		
		[cellView setFixed:item.fixed];

        // TODO!: update 'complete' stat image
        return cellView;
    }
}

- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return self.types.count;
    }
    return [self.data[item] count];
}

- (id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return self.types[index];
    }

    return [self.data[item] objectAtIndex:index];
}
- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[XToDoItem class]]) {
        return NO;
    }
    return YES;
}
- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
    NSOutlineView* outlineView = notification.object;

    NSInteger row = [outlineView selectedRow];

    XToDoItem* item = [outlineView itemAtRow:row];

    if ([item isKindOfClass:[XToDoItem class]]) {
        [XToDoModel openItem:item];

    } else {
        [outlineView deselectRow:row];
    }
}

@end
