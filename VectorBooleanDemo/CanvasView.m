//
//  CanvasView.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "CanvasView.h"

static CGRect BoxFrame(CGPoint point)
{
    return CGRectMake(floorf(point.x - 2) - 0.5, floorf(point.y - 2) - 0.5, 5, 5);
}

@interface CanvasView ()

@property (nonatomic, strong) NSMutableArray *paths;

@end

@implementation CanvasView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.paths = [[NSMutableArray alloc] initWithCapacity:3];
        self.showPoints = YES;
        self.showIntersections = YES;
    }
    
    return self;
}

- (void) addPath:(CGPathRef)path withColor:(NSColor *)color
{
    [self.paths addObject:@{@"path": (__bridge id)path, @"color": color}];
}

- (NSUInteger) numberOfPaths
{
    return self.paths.count;
}

- (CGPathRef) pathAtIndex:(NSUInteger)index
{
    return (__bridge CGPathRef)(self.paths[index][@"path"]);
}

- (void) clear
{
    [self.paths removeAllObjects];
}

- (void) drawRect:(NSRect)dirtyRect
{
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
	
    // Draw on a background
	CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
	CGContextFillRect(context, dirtyRect);
	
    // Fill the objects
    for (NSDictionary *object in self.paths) {
        NSColor *color = object[@"color"];
        CGPathRef path = (__bridge CGPathRef)(object[@"path"]);
		
		CGContextSetFillColorWithColor(context, [color highlightWithLevel:0.3].CGColor);
		CGContextAddPath(context, path);
		CGContextFillPath(context);
    }
	
	// Stroke the objects
	for (NSDictionary *object in self.paths) {
		NSColor *color = object[@"color"];
		CGPathRef path = (__bridge CGPathRef)(object[@"path"]);
		
		CGContextSetStrokeColorWithColor(context, color.CGColor);
		CGContextAddPath(context, path);
		CGContextStrokePath(context);
	}
	
    // Draw on the end and control points
    if ( self.showPoints ) {
		CGContextSetLineWidth(context, 1.0);
		CGContextSetLineCap(context, kCGLineCapButt);
		CGContextSetLineJoin(context, kCGLineJoinMiter);
		CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
		
        for (NSDictionary *object in self.paths) {
            CGPathRef path = (__bridge CGPathRef)(object[@"path"]);
            [NSBezierPath setDefaultLineWidth:1.0];
            [NSBezierPath setDefaultLineCapStyle:NSButtLineCapStyle];
            [NSBezierPath setDefaultLineJoinStyle:NSMiterLineJoinStyle];
			
			CGPathEnumerateElementsUsingBlock(path, ^(const CGPathElement *element) {
				switch (element->type) {
					case kCGPathElementMoveToPoint:
					{
						CGPoint point = *(CGPoint *) element->points;
						
						CGContextSetStrokeColorWithColor(context, [NSColor orangeColor].CGColor);
						CGContextFillRect(context, BoxFrame(point));
						CGContextStrokeRect(context, BoxFrame(point));
						break;
					}
						
					case kCGPathElementAddLineToPoint:
					{
						CGPoint point = *(CGPoint *) element->points;
						
						CGContextSetStrokeColorWithColor(context, [NSColor orangeColor].CGColor);
						CGContextFillRect(context, BoxFrame(point));
						CGContextStrokeRect(context, BoxFrame(point));
						break;
					}
						
					case kCGPathElementAddQuadCurveToPoint:
					{
						NSPoint controlPoint = *(NSPoint *) &element->points[0];
						NSPoint point = *(NSPoint *) &element->points[1];
						
						CGContextSetStrokeColorWithColor(context, [NSColor orangeColor].CGColor);
						CGContextFillRect(context, BoxFrame(point));
						CGContextStrokeRect(context, BoxFrame(point));
						
						CGContextSetStrokeColorWithColor(context, [NSColor blackColor].CGColor);
						CGContextFillRect(context, BoxFrame(controlPoint));
						CGContextStrokeRect(context, BoxFrame(controlPoint));
						break;
					}
						
					case kCGPathElementAddCurveToPoint:
					{
						NSPoint controlPoint1 = *(NSPoint *) &element->points[0];
						NSPoint controlPoint2 = *(NSPoint *) &element->points[1];
						NSPoint point = *(NSPoint *) &element->points[2];
						
						CGContextSetStrokeColorWithColor(context, [NSColor orangeColor].CGColor);
						CGContextFillRect(context, BoxFrame(point));
						CGContextStrokeRect(context, BoxFrame(point));
						
						CGContextSetStrokeColorWithColor(context, [NSColor blackColor].CGColor);
						CGContextFillRect(context, BoxFrame(controlPoint1));
						CGContextStrokeRect(context, BoxFrame(controlPoint1));
						
						CGContextSetStrokeColorWithColor(context, [NSColor blackColor].CGColor);
						CGContextFillRect(context, BoxFrame(controlPoint2));
						CGContextStrokeRect(context, BoxFrame(controlPoint2));
						break;
					}
						
					case kCGPathElementCloseSubpath:
						break;
				}
			});
        }
    }
    
    // If we have exactly two objects, show where they intersect
//    if ( self.showIntersections && (self.paths).count == 2 ) {
//        CGPathRef path1 = (__bridge CGPathRef)(self.paths[0][@"path"]);
//        CGPathRef path2 = (__bridge CGPathRef)(self.paths[1][@"path"]);
//        NSArray *curves1 = [FBBezierCurve bezierCurvesFromPath:path1];
//        NSArray *curves2 = [FBBezierCurve bezierCurvesFromPath:path2];
//		
//		CGContextSetLineWidth(context, 1.0);
//		CGContextSetLineCap(context, kCGLineCapButt);
//		CGContextSetLineJoin(context, kCGLineJoinMiter);
//		CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
//		
//        for (FBBezierCurve *curve1 in curves1) {
//            for (FBBezierCurve *curve2 in curves2) {
//                [curve1 intersectionsWithBezierCurve:curve2 overlapRange:nil withBlock:^(FBBezierIntersection *intersection, BOOL *stop) {
//					
//					if ( intersection.isTangent ) {
//						CGContextSetStrokeColorWithColor(context, [NSColor purpleColor].CGColor);
//					} else {
//						CGContextSetStrokeColorWithColor(context, [NSColor greenColor].CGColor);
//					}
//					
//					CGContextFillEllipseInRect(context, BoxFrame(intersection.location));
//					CGContextStrokeEllipseInRect(context, BoxFrame(intersection.location));
//                }];
//            }
//        }
//    }
}

@end
