//
//  CanvasView.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Canvas;

@interface CanvasView : NSView  

- (void) addPath:(NSBezierPath *)path withColor:(NSColor *)color;
- (void) clear;

@property (nonatomic, readonly) NSUInteger numberOfPaths;
- (NSBezierPath *) pathAtIndex:(NSUInteger)index;

- (void) drawRect:(NSRect)dirtyRect;

@property BOOL showPoints;
@property BOOL showIntersections;

@end
