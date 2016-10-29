//
//  CanvasView.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "CanvasView.h"
#import "NSBezierPath+Utilities.h"
#import "FBBezierCurve.h"
#import "FBBezierIntersection.h"

static NSRect BoxFrame(NSPoint point)
{
    return NSMakeRect(floorf(point.x - 2) - 0.5, floorf(point.y - 2) - 0.5, 5, 5);
}

@interface CanvasView ()

@property (nonatomic, strong) NSMutableArray *paths;

@end

@implementation CanvasView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.paths = [[NSMutableArray alloc] initWithCapacity:3];
        self.showPoints = YES;
        self.showIntersections = YES;
    }
    
    return self;
}

- (void) addPath:(NSBezierPath *)path withColor:(NSColor *)color
{
    [self.paths addObject:@{@"path": path, @"color": color}];
}

- (NSUInteger) numberOfPaths
{
    return [self.paths count];
}

- (NSBezierPath *) pathAtIndex:(NSUInteger)index
{
    return self.paths[index][@"path"];
}

- (void) clear
{
    [self.paths removeAllObjects];
}

- (void) drawRect:(NSRect)dirtyRect
{
    // Draw on a background
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // Draw on the objects
    for (NSDictionary *object in self.paths) {
        NSColor *color = object[@"color"];
        NSBezierPath *path = object[@"path"];
        [[color highlightWithLevel:0.3] set];
        [path fill];
		
		[color set];
		[path stroke];
    }
    
    // Draw on the end and control points
    if ( self.showPoints ) {
        for (NSDictionary *object in self.paths) {
            NSBezierPath *path = object[@"path"];
            [NSBezierPath setDefaultLineWidth:1.0];
            [NSBezierPath setDefaultLineCapStyle:NSButtLineCapStyle];
            [NSBezierPath setDefaultLineJoinStyle:NSMiterLineJoinStyle];
            
            for (NSInteger i = 0; i < [path elementCount]; i++) {
                NSBezierElement element = [path fb_elementAtIndex:i];
                [[NSColor whiteColor] set];
                [NSBezierPath fillRect:BoxFrame(element.point)];
				[[NSColor orangeColor] set];
				[NSBezierPath strokeRect:BoxFrame(element.point)];
                if ( element.kind == NSCurveToBezierPathElement ) {
					[[NSColor whiteColor] set];
					[NSBezierPath fillRect:BoxFrame(element.controlPoints[0])];
					[NSBezierPath fillRect:BoxFrame(element.controlPoints[1])];
                    [[NSColor blackColor] set];
                    [NSBezierPath strokeRect:BoxFrame(element.controlPoints[0])];
                    [NSBezierPath strokeRect:BoxFrame(element.controlPoints[1])];
                }
            }
        }
    }
    
    // If we have exactly two objects, show where they intersect
    if ( self.showIntersections && [self.paths count] == 2 ) {
        NSBezierPath *path1 = self.paths[0][@"path"];
        NSBezierPath *path2 = self.paths[1][@"path"];
        NSArray *curves1 = [FBBezierCurve bezierCurvesFromBezierPath:path1];
        NSArray *curves2 = [FBBezierCurve bezierCurvesFromBezierPath:path2];
		
        for (FBBezierCurve *curve1 in curves1) {
            for (FBBezierCurve *curve2 in curves2) {
                [curve1 intersectionsWithBezierCurve:curve2 overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
                    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:BoxFrame(intersection.location)];
					
					[[NSColor whiteColor] set];
					[circle fill];
					if ( intersection.isTangent )
						[[NSColor purpleColor] set];
					else
						[[NSColor greenColor] set];
                    [circle stroke];
                }];
            }
        }
    }
}

@end
