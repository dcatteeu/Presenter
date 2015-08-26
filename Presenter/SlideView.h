//
//  SlideView.h
//  SlideView
//
//  Created by David Catteeuw on 21/08/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface SlideView : NSView

@property NSColor *color;
@property (nonatomic) PDFDocument *pdfDocument; //Nonatomic since it has a custom setter.
@property (nonatomic) NSUInteger currentPageIndex; //Nonatomic since it has a custom setter.

@end
