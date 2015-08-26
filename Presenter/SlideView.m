//
//  SlideView.m
//  SlideView
//
//  Created by David Catteeuw on 21/08/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

#import "SlideView.h"

@interface SlideView ()
@property NSSize maxPageSize;
@end

@implementation SlideView

@synthesize pdfDocument = _pdfDocument; // Necessary since we have a custom setter.

- (CGFloat)aspectRatio {
    return self.bounds.size.width / self.bounds.size.height;
}

- (void)awakeFromNib {
    self.maxPageSize = NSMakeSize(0, 0);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    /* TODO: Remove debug code. */
    [[NSColor redColor] set];
    [NSBezierPath fillRect:dirtyRect];
    NSLog(@"SlideView bounds: %.0f, %.0f, %.0f, %.0f", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
    
    self.boundsSize = self.maxPageSize;
    
    if (self.pdfDocument) {
        if (self.currentPageIndex < self.pdfDocument.pageCount) {
            PDFPage *page = [self.pdfDocument pageAtIndex:self.currentPageIndex];
            if (page) {
                // TODO: Center the content if it is smaller than other pages?
                [page drawWithBox:kPDFDisplayBoxMediaBox];
            }
        } else {
            /* This may happen if the SlideView shows the next slide of the presentation, while the current slide is actually the last one PDFPage of the PDFDocument. */
            [self.color set];
            [NSBezierPath fillRect:dirtyRect];
        }
    }
}

//- (void)layout {
//    
//}

- (void)setCurrentPageIndex:(NSUInteger)currentPageIndex {
    _currentPageIndex = currentPageIndex;
    
    [self setNeedsDisplay:YES];
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument {
    _pdfDocument = pdfDocument;
    
    /* Initialize index. */
    self.currentPageIndex = 0;
    
    /* Set bounds so that all PDFPages fall within. TODO: What with the origin? */
    NSSize maxPageSize = NSMakeSize(0, 0);
    for (int i = 0; i < self.pdfDocument.pageCount; i++) {
        PDFPage *page = [self.pdfDocument pageAtIndex:self.currentPageIndex];
        
        NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
        maxPageSize.height = MAX(maxPageSize.height, pageBounds.size.height);
        maxPageSize.width = MAX(maxPageSize.width, pageBounds.size.width);
    }
    // TODO: set bounds once, then update if there is a change, for example, in layout?.
    // TODO: The aspect ratio constraint of the SlideView should now be updated.
    self.maxPageSize = maxPageSize;
    self.boundsSize = maxPageSize;
    
//    /* Disable the widget of 'Text' annotations. */
//    for (int i = 0; i < self.pdfDocument.pageCount; i++) {
//        PDFPage *page = [self.pdfDocument pageAtIndex:self.currentPageIndex];
//        for (PDFAnnotation *annotation in page.annotations) {
//            if ([annotation.type isEqualToString:@"Text"]) {
//                annotation.shouldDisplay = NO;
//            }
//        }
//    }
    
    [self setNeedsDisplay:YES];
}

@end
