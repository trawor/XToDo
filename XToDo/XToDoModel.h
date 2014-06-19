//
//  XToDoModel.h
//  XToDo
//
//  Created by Travis on 13-11-28.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ProjectSetting.h"

@interface DVTChoice : NSObject
- (id)initWithTitle:(id)arg1 toolTip:(id)arg2 image:(id)arg3 representedObject:(id)arg4;
@end

@interface DVTTextDocumentLocation : NSObject
@property (readonly) NSRange characterRange;
@property (readonly) NSRange lineRange;
@end

@interface DVTTextPreferences : NSObject
+ (id)preferences;
@property BOOL trimWhitespaceOnlyLines;
@property BOOL trimTrailingWhitespace;
@property BOOL useSyntaxAwareIndenting;
@end

@interface DVTSourceTextStorage : NSTextStorage
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)string withUndoManager:(id)undoManager;
- (NSRange)lineRangeForCharacterRange:(NSRange)range;
- (NSRange)characterRangeForLineRange:(NSRange)range;
- (void)indentCharacterRange:(NSRange)range undoManager:(id)undoManager;
@end

@interface DVTFileDataType : NSObject
@property (readonly) NSString* identifier;
@end

@interface DVTFilePath : NSObject
@property (readonly) NSURL* fileURL;
@property (readonly) DVTFileDataType* fileDataTypePresumed;
@end

@interface IDEContainerItem : NSObject
@property (readonly) DVTFilePath* resolvedFilePath;
@end

@interface IDEGroup : IDEContainerItem

@end

@interface IDEFileReference : IDEContainerItem

@end

@interface IDENavigableItem : NSObject
@property (readonly) IDENavigableItem* parentItem;
@property (readonly) id representedObject;

@end

@interface IDEFileNavigableItem : IDENavigableItem
@property (readonly) DVTFileDataType* documentType;
@property (readonly) NSURL* fileURL;
@end

@interface IDEStructureNavigator : NSObject
@property (retain) NSArray* selectedObjects;
@end

@interface IDENavigableItemCoordinator : NSObject
- (id)structureNavigableItemForDocumentURL:(id)arg1 inWorkspace:(id)arg2 error:(id*)arg3;
@end

@interface IDENavigatorArea : NSObject
@property NSArrayController* extensionsController;
- (id)currentNavigator;
@end

@interface IDEWorkspaceTabController : NSObject
@property (readonly) IDENavigatorArea* navigatorArea;
@property (readonly) IDEWorkspaceTabController* structureEditWorkspaceTabController;
@end

@interface IDEDocumentController : NSDocumentController
+ (IDEDocumentController*)sharedDocumentController;
+ (id)editorDocumentForNavigableItem:(id)arg1;
+ (id)retainedEditorDocumentForNavigableItem:(id)arg1 error:(id*)arg2;
+ (void)releaseEditorDocument:(id)arg1;

@end

@interface IDESourceCodeDocument : NSDocument
- (DVTSourceTextStorage*)textStorage;
- (NSUndoManager*)undoManager;
@end

@interface IDESourceCodeComparisonEditor : NSObject
@property (readonly) NSTextView* keyTextView;
@property (retain) NSDocument* primaryDocument;
@end

@interface IDESourceCodeEditor : NSObject
@property (retain) NSTextView* textView;
- (IDESourceCodeDocument*)sourceCodeDocument;
@end

@interface IDEEditorContext : NSObject
- (id)editor; // returns the current editor. If the editor is the code editor, the class is `IDESourceCodeEditor`
@end

@interface IDEEditorArea : NSObject
- (IDEEditorContext*)lastActiveEditorContext;
@end

@interface IDEConsoleArea : NSObject
- (IDEEditorContext*)lastActiveEditorContext;
@end

@interface IDEWorkspaceWindowController : NSObject
@property (readonly) IDEWorkspaceTabController* activeWorkspaceTabController;
- (IDEEditorArea*)editorArea;
@end

@interface IDEWorkspace : NSWorkspace
@property (readonly) DVTFilePath* representingFilePath;
@end

@interface IDEWorkspaceDocument : NSDocument
@property (readonly) IDEWorkspace* workspace;
@end

@interface XToDoItem : NSObject
@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, assign) NSUInteger lineNumber;
@property (nonatomic, assign) int type;
@property (nonatomic, copy) NSString* typeString;
@property (nonatomic, copy) NSString* content;
@end

@interface XToDoModel : NSObject

+ (IDEWorkspaceDocument*)currentWorkspaceDocument;
+ (IDEWorkspaceTabController*)tabController;
+ (IDESourceCodeEditor*)currentEditor;

+ (NSArray*)findItemsWithProjectSetting:(ProjectSetting*)projectSetting projectPath:(NSString*)ProjectPath;

+ (BOOL)openItem:(XToDoItem*)item;

+ (void)cleanAllTempFiles;
+ (NSString*)addPathSlash:(NSString*)path;
+ (NSString*)rootPathMacro;
+ (NSArray*)explandRootPathMacros:(NSArray*)paths projectPath:(NSString*)projectPath;
+ (NSString*)explandRootPathMacro:(NSString*)path projectPath:(NSString*)projectPath;
+ (NSString*)settingFilePathByProjectName:(NSString*)projectName;
+ (ProjectSetting*)projectSettingByProjectName:(NSString*)projectName;
+ (void)saveProjectSetting:(ProjectSetting*)projectSetting ByProjectName:(NSString*)projectName;
@end

extern NSString* const kXToDoTextSizePrefsKey;
extern NSString* const kXToDoTagsKey;
extern NSString* const kNotifyProjectSettingChanged;