//
//  SlideView.m
//  Presenter
//
//  Created by David Catteeuw on 05/07/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

#import "SlideView.h"

@implementation SlideView

- (BOOL)acceptsFirstResponder {
    return NO;
}

- (void)keyDown:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"keyDown");
}

- (void)keyUp:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"keyUp");
}

- (void)magnifyWithEvent:(NSEvent *)event {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"magnifyWithEvent");
}

- (void)mouseDown:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseDown");
}

- (void)mouseDragged:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseDragged");
}

- (void)mouseEntered:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseEntered");
}

- (void)mouseExited:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseExited");
}

- (void)mouseMoved:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseMoved");
}

- (void)mouseUp:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"mouseUp");
}

- (void)scrollLineDown:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollLineDown");
}

- (void)scrollLineUp:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollLineUp");
}

- (void)scrollPageDown:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollPageDown");
}

- (void)scrollPageUp:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollPageUp");
}

- (void)scrollToBeginningOfDocument:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollToBeginningOfDocument");
}

- (void)scrollToEndOfDocument:(id)sender {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollToEndOfDocument");
}

- (void)scrollWheel:(NSEvent *)theEvent {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"scrollWheel");
}

- (void)swipeWithEvent:(NSEvent *)event {
    // Ignore but override to avoid the PDFViews from handling these events.
    NSLog(@"swipeWithEvent");
}

@end
