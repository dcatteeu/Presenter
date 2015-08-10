//
//  ColoredView.m
//  autolayout
//
//  Created by David Catteeuw on 10/08/15.
//  Copyright (c) 2015 David R. Catteeuw. All rights reserved.
//

#import "ColoredView.h"

@implementation ColoredView

- (void)drawRect:(NSRect)dirtyRect {
    [self.color set];
    [NSBezierPath fillRect:dirtyRect];
}

@end
