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
 
    Keys:
        right and down arrow:   next slide
        left and up arrow:      previous slide
        home:                   first slide
        end:                    last slide
        esc:                    quit presentation/rehearsal mode
 
*/

#define SINGLE_SCREEN_TEST 0

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
@property (weak) IBOutlet PDFView *currentPdfView;
@property (weak) IBOutlet PDFView *nextPdfView;
@property (weak) IBOutlet PDFView *publicPdfView;
@property NSUInteger currentSlide;

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
    self.privateScreenIndex = 0;
    self.publicScreenIndex = 1;
    if (SINGLE_SCREEN_TEST) {
        self.publicScreenIndex = 0;
    }
    NSUInteger nofScreens = [[NSScreen screens] count];
    NSLog(@"nofScreens: %u", (unsigned int)nofScreens);
    
    /* Set delegate to catch windowDidExitFullScreen event to restore organizer mode when exiting full screen. */
    [self.publicWindow setDelegate:self];
    [self.privateWindow setDelegate:self];
    
    // To ease debugging, load a PDF.
    self.pdf = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///Users/dcatteeu/Documents/programming/design-patterns-norvig.pdf"]];
    
    /* When opening the application with a PDF file (for example by double clicking the PDF or dragging it on top of the application's icon. application:openFile is called before applicationDidFinishLaunching:, so self.pdf is set, but the hasn't been linked with self.pdfView. */
    if (self.pdf) {
        NSLog(@"Yes");
        [self loadPdf];
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
            //NSLog(@"%@", url);
            // TODO: Check whether we have a PDF.
            self.pdf = [[PDFDocument alloc] initWithURL:url];
            [self loadPdf];
        }
    }];
}



/* ----------------------------------------------------------------
 * Implementation
 */

- (void)loadPdf {
    self.currentSlide = 1;
    [self.pdfView setDocument:self.pdf];
    [self.publicPdfView setDocument:self.pdf];
    [self.currentPdfView setDocument:self.pdf];
    [self.nextPdfView setDocument:self.pdf];
    [self.nextPdfView goToNextPage:self];
}

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
    if (SINGLE_SCREEN_TEST || [[NSScreen screens] count] >= 2) {
        [self showPrivateAndPublicWindow];
    } else {
        [self showPublicWindowOnly];
    }
}

/* Rehearsal mode is like presentation mode, but always shows at least the private window. If there is no second screen, the user still wants to see his comments, etc. */
- (void)switchToRehearsalMode {
    if (SINGLE_SCREEN_TEST || [[NSScreen screens] count] >= 2) {
        [self showPrivateAndPublicWindow];
    } else {
        [self showPrivateWindowOnly];
    }
}

// TODO: Deal with more than 2 screens by selecting 1 as the private and all others as public. You can cycle through the screen to select one as private.

/* Assumes there is only one screen. */
- (void)showPrivateWindowOnly {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.privateWindow fullScreenOn:[[NSScreen screens] objectAtIndex:0]];
}

/* Assumes there is only one screen. */
- (void)showPublicWindowOnly {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.publicWindow fullScreenOn:[[NSScreen screens] objectAtIndex:0]];
}

/* Assumes there are two screens. */
- (void)showPrivateAndPublicWindow {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.privateWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.privateScreenIndex]];
    [self showWindow:self.publicWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.publicScreenIndex]];
}

- (void)showWindow:(NSWindow *)window fullScreenOn:(NSScreen *)screen {
    if (SINGLE_SCREEN_TEST) {
        [window orderFront:self];
    } else {
        NSRect rect = [screen visibleFrame];
        [window setFrame:rect display:YES];
        [window orderFront:self];
        [window toggleFullScreen:self];
    }
}

@end
