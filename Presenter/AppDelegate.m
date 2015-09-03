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
@property PDFDocument *pdf;

@property NSArray *allSlideViews;
@property NSArray *allButOneAheadSlideView;

@property (weak) IBOutlet NSWindow *organizerWindow;
@property (weak) IBOutlet NSWindow *privateWindow;
@property (weak) IBOutlet NSWindow *publicWindow;

/* Organizer window elements */
@property (weak) IBOutlet PDFThumbnailView *pdfThumbnailView;
@property (weak) IBOutlet PDFView *pdfView;

/* Public window elements */
@property (weak) IBOutlet SlideView *publicSlideView;

/* Private window elements */
@property (weak) IBOutlet ColoredView *backgroundView;
@property (weak) IBOutlet ColoredView *clocksView;
@property (weak) IBOutlet NSTextField *clockLabel;
@property (weak) IBOutlet NSTextField *runningTimeLabel;
@property NSTimeInterval startTime;
@property NSTimer *timer;
@property (weak) IBOutlet NSTextField *currentSlideLabel;
@property (weak) IBOutlet NSView *currentSlideView;
@property (weak) IBOutlet NSTextField *oneAheadSlideLabel;
@property (weak) IBOutlet SlideView *oneAheadSlideView;
@property (weak) IBOutlet NSTextField *notesTextField;
@property NSArray *notes;

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
//    NSWindow *window = (NSWindow *)notification.object;
//    if (window == self.publicWindow || window == self.privateWindow) {
        [self switchToOrganizerMode];
//    }
}



/* ----------------------------------------------------------------
 * NSApplicationDelegate implementation 
 */

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    self.pdf = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:filename]];
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self registerDefaults];
    
    [self.pdfThumbnailView setPDFView:self.pdfView];
    
    /* Put all pdf views in an array for bulk processing. */
    self.allSlideViews = [NSArray arrayWithObjects:self.publicSlideView, self.currentSlideView, self.oneAheadSlideView, nil];
    self.allButOneAheadSlideView = [NSArray arrayWithObjects:self.publicSlideView, self.currentSlideView, nil];
    
    self.privateScreenIndex = 0;
    self.publicScreenIndex = 1;
    
    /* Set delegate to catch windowDidExitFullScreen event to restore organizer mode when exiting full screen. */
    [self.publicWindow setDelegate:self];
    [self.privateWindow setDelegate:self];
    
#ifdef DEBUG
    /* To ease debugging, load a PDF. */
    self.pdf = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///Users/dcatteeu/Projects/Presenter/doc/example.pdf"]];
#endif
    
    /* When opening the application with a PDF file (for example by double clicking the PDF or dragging it on top of the application's icon. application:openFile is called before applicationDidFinishLaunching:, so self.pdf is set, but the hasn't been linked with self.pdfView. Therefore, check. */
    if (self.pdf) {
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
    [self switchToPresentationMode:NO];
}

- (IBAction)rehearse:(id)sender {
    [self switchToPresentationMode:YES];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* url = [panel URLs][0];
            //NSLog(@"%@", url);
            // TODO: Check whether we have a PDF.
            self.pdf = [[PDFDocument alloc] initWithURL:url];
            [self loadPdf];
        }
    }];
}

- (void)loadPdf {
    [self.pdfView setDocument:self.pdf];
    for (SlideView* slideView in self.allSlideViews) {
        [slideView setPdfDocument:self.pdf];
        [slideView setCurrentPageIndex:0];
    }
    [self.oneAheadSlideView setCurrentPageIndex:1];
    
    /* Concatenate all text annotations with an empty line in between and show as this slide's notes. Disable the corresponding widgets. */
    NSMutableArray *notes = [[NSMutableArray alloc] initWithCapacity:self.pdf.pageCount];
    for (int i = 0; i < self.pdf.pageCount; i++) {
        PDFPage *page = [self.pdf pageAtIndex:i];
        NSString *str = [NSString stringWithFormat:@""];
        for (PDFAnnotation *annotation in [page annotations]) {
            if ([annotation.type isEqualToString:@"Text"]) {
                if ([str isNotEqualTo:@""]) {
                    str = [str stringByAppendingString:@"\n\n"];
                }
                str = [str stringByAppendingString:annotation.contents];
                
                [annotation setShouldDisplay:NO];
            }
        }
        notes[i] = str;
    }
    self.notes = [NSArray arrayWithArray:notes];
}

- (void)keyDown:(NSEvent *)event {
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
            [self previousSlide:self.allButOneAheadSlideView oneAheadSlideView:self.oneAheadSlideView label:self.currentSlideLabel];
            break;
            
            // right or down
        case NSRightArrowFunctionKey:
        case 0x7c:
        case NSDownArrowFunctionKey:
        case 0x7d:
            if (self.state == stateWait) {
                [self startPresenting];
            }
            [self nextSlide:self.allButOneAheadSlideView oneAheadSlideView:self.oneAheadSlideView label:self.currentSlideLabel];
            break;
            
        default:
            NSLog(@"Unhandled keyDown: %@ (0x%x)", event.charactersIgnoringModifiers,  event.keyCode);
    }
}



/* ----------------------------------------------------------------
 * Implementation window handling
 */

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
        [self updateTimeLabels:nil];
    } else {
        [self showPublicWindowOnly];
    }
    
    /* Set first responder to catch key events. This can only be done once the windows are shown and this may be the first time. */
    [self.publicWindow makeFirstResponder:self];
    [self.privateWindow makeFirstResponder:self];
    
    if (rehearse || [[NSScreen screens] count] >= 2) {
        [self gotoSlide:0 views:self.allSlideViews oneAheadSlideView:self.oneAheadSlideView label:self.currentSlideLabel];
        
#ifdef DEBUG
        // TODO: Remove debug code.
        [((ColoredView *)self.currentSlideView.superview) setColor:[NSColor blueColor]];
        [((ColoredView *)self.oneAheadSlideView.superview) setColor:[NSColor greenColor]];
        [self.privateWindow.childWindows[0] setNeedsDisplay:YES];
#endif
    }
}

// TODO: Deal with more than 2 screens by selecting 1 as the private and all others as public. You can cycle through the screen to select one as private.

/* Assumes there is only one screen. */
- (void)showPrivateWindowOnly {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.privateWindow fullScreenOn:[NSScreen screens][0]];
}

/* Assumes there is only one screen. */
- (void)showPublicWindowOnly {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.publicWindow fullScreenOn:[NSScreen screens][0]];
}

/* Assumes there are two screens. */
- (void)showPrivateAndPublicWindow {
    [self.organizerWindow orderOut:self];
    [self showWindow:self.publicWindow fullScreenOn:[NSScreen screens][self.publicScreenIndex]];
    [self showWindow:self.privateWindow fullScreenOn:[NSScreen screens][self.privateScreenIndex]];
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
    
#ifdef DEBUG
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

- (void)nextSlide:(NSArray *)slideViews oneAheadSlideView:(SlideView *)oneAheadSlideView label:(NSTextField *)label {
    NSUInteger nextPageNumber = [slideViews[0] currentPageIndex] + 1;
    [self gotoSlide:nextPageNumber views:slideViews oneAheadSlideView:oneAheadSlideView label:label];
}

- (void)previousSlide:(NSArray *)slideViews oneAheadSlideView:(SlideView *)oneAheadSlideView label:(NSTextField *)label {
    NSUInteger previousPageNumber = [slideViews[0] currentPageIndex] - 1;
    [self gotoSlide:previousPageNumber views:slideViews oneAheadSlideView:oneAheadSlideView label:label];
}

/* Any page switch passes through this function. TODO: Remove parameter label or add oneAheadLabel*/
- (void)gotoSlide:(NSUInteger)slideIndex views:(NSArray *)slideViews oneAheadSlideView:(SlideView *)oneAheadSlideView label:(NSTextField *)label {
    if (slideIndex >= self.pdf.pageCount) {
        NSLog(@"AppDelegate gotoSlide:%lu - index out of bounds", slideIndex);
        return;
    }
    
    // Notes
    [self.notesTextField setStringValue:self.notes[slideIndex]];
    
    // SlideViews
    NSUInteger nextSlideIndex = slideIndex + 1;
    for (SlideView *slideView in slideViews) {
        [slideView setCurrentPageIndex:slideIndex];
    }
    [oneAheadSlideView setCurrentPageIndex:nextSlideIndex];
    
    // Labels above SlideViews (for humans, pages start at 1, for PDFDocument, they start at 0)
    [self.currentSlideLabel setStringValue:[NSString stringWithFormat:@"Current: Slide %lu of %lu", 1 + slideIndex, self.pdf.pageCount]];
    if (nextSlideIndex < self.pdf.pageCount) {
        [self.oneAheadSlideLabel setStringValue:[NSString stringWithFormat:@"Next: Slide %lu of %lu", 1 + nextSlideIndex, self.pdf.pageCount]];
    } else {
        [self.oneAheadSlideLabel setStringValue:[NSString stringWithFormat:@"End of Show"]];
    }
}

@end
