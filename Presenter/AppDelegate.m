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

@import Quartz;

#import "AppDelegate.h"
#import "SlideView.h"
#import "ColoredView.h"

static BOOL FULLSCREEN = YES;
typedef enum { stateOrganize, stateWait, statePresent } State;

@interface AppDelegate ()

@property State state;

@property NSUInteger privateScreenIndex;
@property NSUInteger publicScreenIndex;

@property (weak) IBOutlet NSWindow *organizerWindow;
@property (weak) IBOutlet NSWindow *privateWindow;
@property (weak) IBOutlet NSWindow *publicWindow;

@property PDFDocument *pdf;
@property (weak) IBOutlet PDFView *pdfView;
@property (weak) IBOutlet SlideView *publicSlideView;
@property NSArray *allPdfViews;
@property NSArray *allButOneAheadPdfView;

/* This PDF is used by the oneAheadSlideView to show a black slide when at the end of the presentation. */
@property PDFDocument *blackPdf;

/* Private window elements */
@property (weak) IBOutlet ColoredView *backgroundView;
@property (weak) IBOutlet NSTextField *clockLabel;
@property (weak) IBOutlet NSTextField *runningTimeLabel;
@property NSTimeInterval startTime;
@property NSTimer *timer;
@property (weak) IBOutlet NSTextField *currentSlideLabel;
@property (weak) IBOutlet SlideView *currentSlideView;
@property (weak) IBOutlet NSTextField *oneAheadSlideLabel;
@property (weak) IBOutlet SlideView *oneAheadSlideView;
@property (weak) IBOutlet NSTextField *notesTextField;

- (IBAction)present:(id)sender;
- (IBAction)rehearse:(id)sender;
- (IBAction)openDocument:(id)sender;

@end

@implementation AppDelegate



/* ----------------------------------------------------------------
 * Preferences
 */
- (void)registerDefaults {
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:@0.2, @"heightComments", @0.5, @"widthCurrentSlide", @0.6, @"slideAspectRatio", @10.0, @"topCurrentSlide", @10.0, @"leftCurrentSlide", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


/* ----------------------------------------------------------------
 * NSWindowDelegate implementation 
 */

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    NSLog(@"windowDidExitFullScreen:");
//    NSWindow *window = (NSWindow *)notification.object;
//    if (window == self.publicWindow || window == self.privateWindow) {
        [self switchToOrganizerMode];
//    }
}



/* ----------------------------------------------------------------
 * NSApplicationDelegate implementation 
 */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self registerDefaults];
    
    /* Put all pdf views in an array for bulk processing. */
    self.allPdfViews = [NSArray arrayWithObjects:self.pdfView, self.publicSlideView, self.currentSlideView, self.oneAheadSlideView, nil];
    self.allButOneAheadPdfView = [NSArray arrayWithObjects:self.pdfView, self.publicSlideView, self.currentSlideView, nil];
    
    self.privateScreenIndex = 0;
    self.publicScreenIndex = 1;
    NSUInteger nofScreens = [[NSScreen screens] count];
    NSLog(@"nofScreens: %u", (unsigned int)nofScreens);
    
    /* Set delegate to catch windowDidExitFullScreen event to restore organizer mode when exiting full screen. */
    [self.publicWindow setDelegate:self];
    [self.privateWindow setDelegate:self];
    
    /* Layout private window manually according to preferences. */
    //[self layoutPrivateWindow];
    
    /* To ease debugging, load a PDF. */
    self.pdf = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///Users/dcatteeu/Projects/Presenter/doc/example.pdf"]];
    
    /* When opening the application with a PDF file (for example by double clicking the PDF or dragging it on top of the application's icon. application:openFile is called before applicationDidFinishLaunching:, so self.pdf is set, but the hasn't been linked with self.pdfView. Therefore, check. */
    if (self.pdf) {
        NSLog(@"Yes");
        [self loadPdf];
    }
    
    self.blackPdf = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///Users/dcatteeu/Projects/Presenter/doc/black.pdf"]];;
    
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
    [self switchToPresentationMode:NO];
}

- (IBAction)rehearse:(id)sender {
    [self switchToPresentationMode:YES];
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
    for (PDFView* pdfView in self.allPdfViews) {
        [pdfView setDocument:self.pdf];
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
        [pdfView setAutoScales:YES];
        [pdfView setDisplaysPageBreaks:NO];
    }
    
    /* Slide indices start at 0. */
    [self gotoSlide:0 views:self.allButOneAheadPdfView oneAheadPdfView:self.oneAheadSlideView label:self.currentSlideLabel];
}

- (void)keyDown:(NSEvent *)event {
    NSLog(@"keyDown: %@ (0x%x)", event.charactersIgnoringModifiers,  event.keyCode);
    // TODO: replace keys by constants, but where are they defined?
    switch (event.keyCode) {
            // escape
        case 0x35:
            [self switchToOrganizerMode];
            break;
            
            // up or left
        case NSUpArrowFunctionKey:
        case 0x7e:
        case NSLeftArrowFunctionKey:
        case 0x7b:
            if (self.state == stateWait) {
                [self startPresenting];
            }
            [self previousSlide:self.allButOneAheadPdfView oneAheadPdfView:self.oneAheadSlideView label:self.currentSlideLabel];
            break;
            
            // right or down
        case NSRightArrowFunctionKey:
        case 0x7c:
        case NSDownArrowFunctionKey:
        case 0x7d:
            if (self.state == stateWait) {
                [self startPresenting];
            }
            [self nextSlide:self.allButOneAheadPdfView oneAheadPdfView:self.oneAheadSlideView label:self.currentSlideLabel];
            break;
            
        default:
            NSLog(@"Unhandled keyDown: %@ (0x%x)", event.charactersIgnoringModifiers,  event.keyCode);
    }
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
    [self.timer invalidate];
    self.state = stateOrganize;
    
    if (self.publicWindow.styleMask & NSFullScreenWindowMask) {
        [self.publicWindow toggleFullScreen:self];
    }
    [self.publicWindow setLevel:NSNormalWindowLevel];
    [self.publicWindow orderOut:self];
    
    if (self.privateWindow.styleMask & NSFullScreenWindowMask) {
        [self.privateWindow toggleFullScreen:self];
    }
    [self.privateWindow setLevel:NSNormalWindowLevel];
    [self.privateWindow orderOut:self];
    
    [self.organizerWindow setLevel:NSNormalWindowLevel];
    [self.organizerWindow orderFront:self];
}

/* Presentation mode always shows at least the public window. If there is no second screen, the slides are shown on the primary screen assuming that other people are watching and no comments, etc. are visible. Rehearsal mode is like presentation mode, but always shows at least the private window. If there is no second screen, the user still wants to see his comments, etc. */
- (void)switchToPresentationMode:(BOOL)rehearse {
    self.state = stateWait;
    
    if ([[NSScreen screens] count] >= 2) {
        [self showPrivateAndPublicWindow];
        [self updateTimeLabels:nil];
    } else if (rehearse) {
        [self showPrivateWindowOnly];
    } else {
        [self showPublicWindowOnly];
        [self updateTimeLabels:nil];
    }
    
    /* Set first responder to catch key events. This can only be done once the windows are shown and this may be the first time. */
    [self.publicWindow makeFirstResponder:self];
    [self.privateWindow makeFirstResponder:self];
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
    NSRect rect = [screen visibleFrame];
    [window setFrame:rect display:YES];
    [window orderFront:self];
    if (FULLSCREEN) {
        [window toggleFullScreen:self];
    }
}

- (void)updateTimeLabels:(NSTimer *)timer {
    /* Update only when in presentation mode. */
    if (self.state == stateOrganize) {
        return;
    }
    
    NSDate *now = [[NSDate alloc] init];
    [self updateClock:now label:self.clockLabel];
    
    CFTimeInterval runningTime = 0;
    if (self.state == statePresent) {
        runningTime = CACurrentMediaTime() - self.startTime;
    }
    [self updateRunningTime:runningTime label:self.runningTimeLabel];
    
    /* To poll at the correct moment, schedule a timer at the next second. Add 1.5 seconds and round down to the second. */
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *next = [now dateByAddingTimeInterval:1.5];
    NSDateComponents *comps = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:now];
    next = [cal dateFromComponents:comps];
    
#ifndef NDEBUG
    comps = [cal components:NSCalendarUnitNanosecond fromDate:next];
    assert(comps.nanosecond == 0);
#endif
    
    timer = [[NSTimer alloc] initWithFireDate:next interval:0 target:self selector:@selector(updateTimeLabels:) userInfo:nil repeats:NO];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)updateClock:(NSDate *)date label:(NSTextField *)label {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeAsString = [dateFormatter stringFromDate:date];
    [label setStringValue:timeAsString];
}

- (void)updateRunningTime:(NSUInteger) timeInterval label:(NSTextField *)label {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSDateComponents *runningTimeComponents = [[NSDateComponents alloc] init];
    NSUInteger secondsPerMinute = 60;
    NSUInteger minutesPerHour = 60;
    runningTimeComponents.second = timeInterval % secondsPerMinute;
    timeInterval = timeInterval / secondsPerMinute;
    runningTimeComponents.minute = timeInterval % minutesPerHour;
    timeInterval = timeInterval / minutesPerHour;
    runningTimeComponents.hour = timeInterval;
    NSString *runningTimeAsString = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)runningTimeComponents.hour, (long)runningTimeComponents.minute, (long)runningTimeComponents.second];
    [label setStringValue:runningTimeAsString];
}

- (void)startPresenting {
    self.startTime = CACurrentMediaTime();
    self.state = statePresent;
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
    if (slideIndex >= pdf.pageCount) {
        return;
    }
    
    /* PDF views do not allow to jump to a specific slide number. You can jump to a specific page. And you can find the page for a specific page number (called index) from the PDF document. */
    PDFPage *page = [pdf pageAtIndex:slideIndex];
    for (PDFView *pdfView in pdfViews) {
        [pdfView goToPage:page];
    }
    
    /* Concatenate all text annotations with an empty line in between and show as this slide's notes. */
    NSString *str = [NSString stringWithFormat:@""];
    for (PDFAnnotation *annotation in [page annotations]) {
        if ([annotation.type isEqualToString:@"Text"]) {
            if ([str isNotEqualTo:@""]) {
                str = [str stringByAppendingString:@"\n\n"];
            }
            str = [str stringByAppendingString:annotation.contents];
        }
    }
    [self.notesTextField setStringValue:str];
    
    /* To keep the oneAheadPdfView exactly one slide ahead, check whether, or not, we are at the end. */
    NSUInteger nextSlideIndex = slideIndex + 1;
    if (nextSlideIndex < pdf.pageCount) {
        [oneAheadPdfView setDocument:pdf];
        page = [pdf pageAtIndex:nextSlideIndex];
        [oneAheadPdfView goToPage:page];
        [self.oneAheadSlideLabel setStringValue:[NSString stringWithFormat:@"Next: Slide %lu of %lu", 1 + nextSlideIndex, pdf.pageCount]];
    } else {
        [oneAheadPdfView setDocument:self.blackPdf];
        [self.oneAheadSlideLabel setStringValue:[NSString stringWithFormat:@"End of Show"]];
    }
    
    [label setStringValue:[NSString stringWithFormat:@"Current: Slide %lu of %lu", 1 + slideIndex, pdf.pageCount]];
}

- (NSUInteger)currentSlideIndex:(PDFView *)view {
    PDFPage *currentPage = view.currentPage;
    NSUInteger currentPageNumber = [view.document indexForPage:currentPage];
    return currentPageNumber;
}

@end
