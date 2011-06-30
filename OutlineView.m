#import "SwizzleMacros.h"
#import "OutlineView.h"

#import <Quartz/Quartz.h>

@interface ComBelkadanTMQuickLook_OutlineView () <QLPreviewPanelDataSource, QLPreviewPanelDelegate>
@end


@implementation ComBelkadanTMQuickLook_OutlineView
+ (void)initialize {
	if (self != [ComBelkadanTMQuickLook_OutlineView class]) return;

	Class oakOutlineView = NSClassFromString(@"OakOutlineView");

	// QLPreviewPanelController
	COPY_METHOD(self, oakOutlineView, acceptsPreviewPanelControl:);
	COPY_METHOD(self, oakOutlineView, beginPreviewPanelControl:);
	COPY_METHOD(self, oakOutlineView, endPreviewPanelControl:);

	// QLPreviewPanelDataSource
	COPY_METHOD(self, oakOutlineView, numberOfPreviewItemsInPreviewPanel:);
	COPY_METHOD(self, oakOutlineView, previewPanel:previewItemAtIndex:);
	
	// QLPreviewPanelDelegate
	COPY_METHOD(self, oakOutlineView, previewPanel:handleEvent:);

	// Action method + spacebar trigger
	COPY_METHOD(self, oakOutlineView, ComBelkadanTMQuickLook_quickLook:);
	COPY_AND_EXCHANGE(self, oakOutlineView, ComBelkadanTMQuickLook_, keyDown:);
}

- (void)ComBelkadanTMQuickLook_quickLook:(id)sender {	
	NSInteger row = [self clickedRow];
	if (row != -1) {
		if (![[self selectedRowIndexes] containsIndex:row]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		}
	}
	
	[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:sender];
}

#pragma mark -

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
	panel.dataSource = self;
	panel.delegate = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
	return [self numberOfSelectedRows];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
	NSIndexSet *rows = [self selectedRowIndexes];
	
	// Trying to get the 'index'th index from 'rows'...yuck!
	// This is O(n^2) to get all the items, but how often is the selection that big anyway?
	// FIXME: We should still cache this.
	__block NSInteger count = 0;
	__block id item = nil;
	[rows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		if (count == index) {
			item = [self itemAtRow:row];
			*stop = YES;
		}
		++count;
	}];
	
	NSString *path = [item valueForKey:@"filename"];
	if (!path) path = [item valueForKey:@"sourceDirectory"];
	NSAssert(path != nil, @"Unknown TextMate project item");

	return [NSURL fileURLWithPath:path];
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
	// Pass along key events to allow navigation of the outline view.
	switch ([event type]) {
	case NSKeyDown:
		[self keyDown:event];
		break;
	case NSKeyUp:
		[self keyUp:event];
		break;
	default:
		return NO;
	}
	
	[panel reloadData];
	return YES;
}

#pragma mark -

- (void)ComBelkadanTMQuickLook_keyDown:(NSEvent *)theEvent {
	if ([[theEvent charactersIgnoringModifiers] isEqual:@" "]) {
		[self ComBelkadanTMQuickLook_quickLook:nil];
	} else {
		[self ComBelkadanTMQuickLook_keyDown:theEvent];
	}
}
@end
