//
//  SlideView.m
//  SlideView
//
//  Created by David Catteeuw on 21/08/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

#import "SlideView.h"



@interface SlideView ()
@property NSSize maxPageSize; // Determines the minimum size of the bounds, but only needs update when a new PDFDocument is set.
@end



@implementation SlideView

@synthesize pdfDocument = _pdfDocument; // Necessary since we have a custom setter.

- (CGFloat)aspectRatio {
    return self.bounds.size.width / self.bounds.size.height;
}

- (void)awakeFromNib {
    self.color = [NSColor blackColor];
    self.maxPageSize = NSMakeSize(0, 0);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    /* The frame and/or the bounds themselves may have changed. */
    self.bounds = computeBounds(self.maxPageSize, self.frame.size);
    
    if (self.pdfDocument) {
        if (self.currentPageIndex < self.pdfDocument.pageCount) {
            PDFPage *page = [self.pdfDocument pageAtIndex:self.currentPageIndex];
            if (page) {
                // TODO: Center the content if it is smaller than the maxPageSize?
                [page drawWithBox:kPDFDisplayBoxMediaBox];
            }
        } else {
            /* This happens if the SlideView shows the next slide of the presentation, while the current slide is actually the last PDFPage of the PDFDocument. */
            [self.color set];
            [NSBezierPath fillRect:dirtyRect];
        }
    }
}

/**
 * The bounds are at least the minimumSize. If their aspect ratio is not the same as the frame's aspect ratio. The bounds are scaled up in one dimension and the origin is moved to center the contents.
 */
NSRect computeBounds(NSSize minimumSize, NSSize frameSize) {
    CGFloat frameAspectRatio = frameSize.width / frameSize.height;
    CGFloat aspectRatio = minimumSize.width / minimumSize.height;
    CGFloat scaleFactor = frameAspectRatio / aspectRatio;
    CGFloat w = minimumSize.width * MAX(scaleFactor, 1);
    CGFloat h = minimumSize.height * MAX(1 / scaleFactor, 1);
    CGFloat x = (minimumSize.width - w) / 2;
    CGFloat y = (minimumSize.height - h) / 2;
    return NSMakeRect(x, y, w, h);
}

- (void)setCurrentPageIndex:(NSUInteger)currentPageIndex {
    _currentPageIndex = currentPageIndex;
    
    [self setNeedsDisplay:YES];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument {
    _pdfDocument = pdfDocument;
    
    /* Initialize index. */
    self.currentPageIndex = 0;
    
    /* Set bounds so that all PDFPages fall within. TODO: What with the origin? Does a PDFPage ever start not at (0,0)? */
    NSSize maxPageSize = NSMakeSize(0, 0);
    for (int i = 0; i < self.pdfDocument.pageCount; i++) {
        PDFPage *page = [self.pdfDocument pageAtIndex:self.currentPageIndex];
        
        NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
        maxPageSize.height = MAX(maxPageSize.height, pageBounds.size.height);
        maxPageSize.width = MAX(maxPageSize.width, pageBounds.size.width);
    }
    self.maxPageSize = maxPageSize;
    
    [self setNeedsDisplay:YES];
}

@end
