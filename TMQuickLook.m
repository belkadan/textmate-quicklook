#import "SwizzleMacros.h"
#import "OutlineView.h"

#import <Cocoa/Cocoa.h>

@interface ComBelkadanTMQuickLook_PlugIn : NSObject
@end

static void setUpMenu (id windowController) {
	// Sneakily extract the outline view from the window controller.
	NSOutlineView *outline = nil;
	object_getInstanceVariable(windowController, "outlineView", (void **)&outline);
	if (!outline) return;
	
	// Add a Quick Look menu item, if it's not there already.
	NSMenu *actionMenu = [outline menu];
	if ([actionMenu indexOfItemWithTarget:outline andAction:@selector(ComBelkadanTMQuickLook_quickLook:)] == -1) {
		NSMenuItem *qlItem = [actionMenu addItemWithTitle:@"Quick Look" action:@selector(ComBelkadanTMQuickLook_quickLook:) keyEquivalent:@""];
		[qlItem setTarget:outline];
	}	
}


@implementation ComBelkadanTMQuickLook_PlugIn
- (id)initWithPlugInController:(id /*<TMPlugInController> */)aController {
	if ((self = [super init])) {
		Class oakOutlineView = NSClassFromString(@"OakOutlineView");
		// First check if someone else is providing QuickLook capabilities.
		if (![oakOutlineView instancesRespondToSelector:@selector(acceptsPreviewPanelControl:)]) {
			// Add QuickLook to the outline view.
			(void)[ComBelkadanTMQuickLook_OutlineView class]; // force +initialize

			// Make sure all future windows will have the Quick Look menu item
			Class pluginClass = [ComBelkadanTMQuickLook_PlugIn class];
			Class oakProjectController = NSClassFromString(@"OakProjectController");
			COPY_AND_EXCHANGE(pluginClass, oakProjectController, ComBelkadanTMQuickLook_, openProjectDrawer:);
			
			// Add the Quick Look menu item to any existing windows
			for (NSWindow *window in [NSApp windows]) {
				id controller = [window windowController];
				if ([controller isKindOfClass:oakProjectController]) {
					setUpMenu(controller);
				}
			}
		}
		
		// No need to keep the plugin instance around after the injection is done.
		[self release]; self = nil;
	}
	return self;
}

#pragma mark OakProjectController

- (void)ComBelkadanTMQuickLook_openProjectDrawer:(id)sender {
	[self ComBelkadanTMQuickLook_openProjectDrawer:sender];
	setUpMenu(self);
}

@end
