//
//  AppDelegate.m
//  Presenter
//
//  Created by David Catteeuw on 30/03/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

/*
    There are 3 modes: organizer, presentation, and rehearsal. In organizer mode, only the organizer window is shown. It allows the user a.o. to select a PDF. Presentation and rehearsal mode are similar. If there are 2 screens connected (for example the laptop's screen and a beamer), both modes show the slides (public window) on the secondary screen and the slides, comments, timer, ... (private window) on the primary screen. Both private and public window are shown full screen. When there is only 1 screen connected, presentation mode shows the slides while rehearsal mode shows slides, comments, timer, ...
 
    The code distinguishes between private and public screens and windows. Private is what is only visible to the user. Public is visible to the user and his audience.
*/

@import Quartz;

#import "AppDelegate.h"

@interface AppDelegate ()

@property NSUInteger privateScreenIndex;
@property NSUInteger publicScreenIndex;

@property (weak) IBOutlet NSWindow *organizerWindow;
@property (weak) IBOutlet NSWindow *privateWindow;
@property (weak) IBOutlet NSWindow *publicWindow;

@property PDFDocument *pdf;
@property (weak) IBOutlet PDFView *pdfView;

- (IBAction)present:(id)sender;
- (IBAction)rehearse:(id)sender;

@end

@implementation AppDelegate

/* ----------------------------------------------------------------
 * NSWindowDelegate implementation 
 */

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    NSLog(@"windowWillExitFullScreen:");
    [self switchToOrganizerMode];
}



/* ----------------------------------------------------------------
 * NSApplicationDelegate implementation 
 */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _privateScreenIndex = 0;
    _publicScreenIndex = 1;
    NSUInteger nofScreens = [[NSScreen screens] count];
    NSLog(@"nofScreens: %u", (unsigned int)nofScreens);
    
    /* Set delegate to catch windowDidExitFullScreen event to restore organizer mode when exiting full screen. */
    [self.publicWindow setDelegate:self];
    [self.privateWindow setDelegate:self];
    
    /* When opening the application with a PDF file (for example by double clicking the PDF or dragging it on top of the application's icon. application:openFile is called before applicationDidFinishLaunching:, so self.pdf is set, but the hasn't been linked with self.pdfView. */
    if (self.pdf) {
        [self.pdfView setDocument:self.pdf];
    }
    
    [self switchToOrganizerMode];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}



/* ----------------------------------------------------------------
 * Events
 */

- (IBAction)present:(id)sender {
    [self switchToPresentationMode];
}

- (IBAction)rehearse:(id)sender {
    [self switchToRehearsalMode];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* url = [[panel URLs] objectAtIndex:0];
            // TODO: Check whether we have a PDF.
            self.pdf = [[PDFDocument alloc] initWithURL:url];
            [self.pdfView setDocument:self.pdf];
        }
    }];
}



/* ----------------------------------------------------------------
 * Implementation
 */

/* In organizer mode only the organizer window is visible while the public and private window are hidden. */
- (void)switchToOrganizerMode {
    [self.publicWindow setLevel:NSNormalWindowLevel];
    [self.publicWindow orderOut:self];
    [self.privateWindow setLevel:NSNormalWindowLevel];
    [self.privateWindow orderOut:self];
    [self.organizerWindow setLevel:NSNormalWindowLevel];
    [self.organizerWindow orderFront:self];
}

/* Presentation mode always shows at least the public window. If there is no second screen, the slides are shown on the primary screen assuming that other people are watching and no comments, etc. are visible. */
- (void)switchToPresentationMode {
    [self.organizerWindow orderOut:self];
    [self.privateWindow orderFront:self];
    [self.privateWindow toggleFullScreen:self];
    if ([[NSScreen screens] count] >= 2) {
        NSRect rect = [[[NSScreen screens] objectAtIndex:self.publicScreenIndex] visibleFrame];
        [self.publicWindow setFrame:rect display:YES];
        [self.publicWindow orderFront:self];
        [self.publicWindow toggleFullScreen:self];
    }
}

/* Rehearsal mode is like presentation mode, but always shows at least the private window. If there is no second screen, the user still wants to see his comments, etc. */
- (void)switchToRehearsalMode {
    [self.organizerWindow orderOut:self];
    [self.privateWindow orderFront:self];
    [self.privateWindow toggleFullScreen:self];
    if ([[NSScreen screens] count] >= 2) {
        NSRect rect = [[[NSScreen screens] objectAtIndex:self.publicScreenIndex] visibleFrame];
        [self.publicWindow setFrame:rect display:YES];
        [self.publicWindow orderFront:self];
        [self.publicWindow toggleFullScreen:self];
    }
}

// TODO: Add functions showPrivateWindowOnly, showPublicWindowOnly.

/* Assumes there are two screens. */
- (void)showPrivateAndPublicWindow {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.privateWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.privateScreenIndex]];
    [self showWindow:self.publicWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.publicScreenIndex]];
}

- (void)showWindow:(NSWindow *)window fullScreenOn:(NSScreen *)screen {
    NSRect rect = [screen visibleFrame];
    [self.publicWindow setFrame:rect display:YES];
    [self.publicWindow orderFront:self];
    [self.publicWindow toggleFullScreen:self];
}

@end
