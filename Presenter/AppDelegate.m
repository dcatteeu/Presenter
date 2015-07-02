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
@property NSArray *pdfViews;

@property (weak) IBOutlet NSTextField *currentSlideLabel;


- (IBAction)present:(id)sender;
- (IBAction)rehearse:(id)sender;

@end

@implementation AppDelegate



/* ----------------------------------------------------------------
 * Preferences
 */
- (void)registerDefaults {
    NSDictionary* defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:@0.2, @"heightComments", @0.5, @"widthCurrentSlide", @0.6, @"slideAspectRatio", @10.0, @"topCurrentSlide", @10.0, @"leftCurrentSlide", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


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
    [self registerDefaults];
    
    /* Put all pdf views in an array for bulk processing. */
    self.pdfViews = [NSArray arrayWithObjects:self.pdfView, self.publicPdfView, self.currentPdfView, nil];
    
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
    
    /* Layout private window manually according to preferences. */
    //[self layoutPrivateWindow];
    
    // To ease debugging, load a PDF.
    self.pdf = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///Users/dcatteeu/Documents/programming/design-patterns-norvig.pdf"]];
    
    /* When opening the application with a PDF file (for example by double clicking the PDF or dragging it on top of the application's icon. application:openFile is called before applicationDidFinishLaunching:, so self.pdf is set, but the hasn't been linked with self.pdfView. Therefore, check. */
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

- (void)keyDown:(NSEvent *)event {
    // TODO: replace keys by constants, but where are they defined?
    switch (event.keyCode) {
        case 0x35:
            [self switchToOrganizerMode];
            break;
            
            // up or left
        case NSUpArrowFunctionKey:
        case 0x7e:
        case NSLeftArrowFunctionKey:
        case 0x7b:
            [self previousSlide:self.pdfViews oneAheadPdfView:self.nextPdfView label:self.currentSlideLabel];
            break;
            
            // right or down
        case NSRightArrowFunctionKey:
        case 0x7c:
        case NSDownArrowFunctionKey:
        case 0x7d:
            [self nextSlide:self.pdfViews oneAheadPdfView:self.nextPdfView label:self.currentSlideLabel];
            break;
            
        default:
            NSLog(@"Unhandled keyDown: %@ (0x%x)", event.charactersIgnoringModifiers,  event.keyCode);
    }
}

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

- (void)loadPdf {
    for (PDFView* pdfView in self.pdfViews) {
        [pdfView setDocument:self.pdf];
    }
    [self.nextPdfView setDocument:self.pdf];
    [self gotoSlide:1 views:self.pdfViews oneAheadPdfView:self.nextPdfView label:self.currentSlideLabel];
}



/* ----------------------------------------------------------------
 * Implementation window handling
 */

//- (void)layoutPrivateWindow {
//    // TODO: programmatically change the view's size
//    NSRect frame = [self.currentPdfView.superview frame];
//    NSLog(@"frame: %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    CGFloat x = [preferences floatForKey:@"leftCurrentSlide"];
//    CGFloat y = [preferences floatForKey:@"topCurrentSlide"];
//    CGFloat w = frame.size.width * [preferences floatForKey:@"widthCurrentSlide"];
//    CGFloat h = w * [preferences floatForKey:@"slideAspectRatio"];
//    frame = NSMakeRect(x, y, w, h);
//    NSLog(@"frame: %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
//    [self.currentPdfView setFrame:frame];
//    [self.currentPdfView setNeedsDisplay:YES];
//}

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
    //[self layoutPrivateWindow];
    
    /* Set first responder to catch key events. */
    [self.publicWindow makeFirstResponder:self];
    [self.privateWindow makeFirstResponder:self];
}

/* Assumes there is only one screen. */
- (void)showPublicWindowOnly {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.publicWindow fullScreenOn:[[NSScreen screens] objectAtIndex:0]];
    
    /* Set first responder to catch key events. */
    [self.publicWindow makeFirstResponder:self];
    [self.privateWindow makeFirstResponder:self];
}

/* Assumes there are two screens. */
- (void)showPrivateAndPublicWindow {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.privateWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.privateScreenIndex]];
    [self showWindow:self.publicWindow fullScreenOn:[[NSScreen screens] objectAtIndex:self.publicScreenIndex]];
    //[self layoutPrivateWindow];
    
    /* Set first responder to catch key events. */
    [self.publicWindow makeFirstResponder:self];
    [self.privateWindow makeFirstResponder:self];
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



/* ----------------------------------------------------------------
 * Implementation slide walking
 */

- (void)nextSlide:(NSArray *)pdfViews oneAheadPdfView:(PDFView *)oneAheadPdfView label:(NSTextField *)label {
    NSUInteger nextPageNumber = [self currentSlideIndex:[pdfViews objectAtIndex:0]] + 1;
    [self gotoSlide:nextPageNumber views:pdfViews oneAheadPdfView:oneAheadPdfView label:label];
}

- (void)previousSlide:(NSArray *)pdfViews oneAheadPdfView:(PDFView *)oneAheadPdfView label:(NSTextField *)label {
    NSUInteger previousPageNumber = [self currentSlideIndex:[pdfViews objectAtIndex:0]] - 1;
    [self gotoSlide:previousPageNumber views:pdfViews oneAheadPdfView:oneAheadPdfView label:label];
}

/* Any page switch passes through this function. */
- (void)gotoSlide:(NSUInteger)slideIndex views:(NSArray *)pdfViews oneAheadPdfView:(PDFView *)oneAheadPdfView label:(NSTextField *)label {
    PDFDocument *pdf = [[pdfViews objectAtIndex:0] document];
    if (slideIndex > pdf.pageCount) {
        return;
    }
    
    /* PDF views do not allow to jump to a specific slide number. You can jump to a specific page. And you can find the page for a specific page number (called index) from the PDF document. */
    PDFPage *page = [pdf pageAtIndex:slideIndex];
    for (PDFView *pdfView in pdfViews) {
        [pdfView goToPage:page];
    }
    
    /* To keep the oneAheadPdfView exactly one slide ahead, check whether, or not, we are at the end. */
    if (slideIndex < pdf.pageCount) {
        page = [pdf pageAtIndex:1 + slideIndex];
        [oneAheadPdfView goToPage:page];
    } else {
        NSLog(@"display the at-end-of-presentation message");
    }
    
    [self updateCurrentSlideLabel:label slide:slideIndex of:pdf.pageCount];
}

- (void)updateCurrentSlideLabel:(NSTextField *)label slide:(NSUInteger)currentSlideIndex of:(NSUInteger)slideCount {
    [label setStringValue:[NSString stringWithFormat:@"Current: Slide %lu of %lu", currentSlideIndex, slideCount]];
}

- (NSUInteger)currentSlideIndex:(PDFView *)view {
    PDFPage *currentPage = view.currentPage;
    NSUInteger currentPageNumber = [view.document indexForPage:currentPage];
    return currentPageNumber;
}

@end
