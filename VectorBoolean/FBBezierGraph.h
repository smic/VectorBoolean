//
//  FBBezierGraph.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class FBBezierContour;
@class FBCurveLocation;

// FBBezierGraph is more or less an exploded version of an CGPath, and
//  the two can be converted between easily. FBBezierGraph allows boolean
//  operations to be performed by allowing the curves to be annotated with
//  extra information such as where intersections happen.
@interface FBBezierGraph : NSObject {
    NSMutableArray *_contours;
    CGRect _bounds;
}

+ (instancetype) bezierGraph;
+ (instancetype) bezierGraphWithPath:(CGPathRef)path;
- (instancetype) initWithPath:(CGPathRef)path;

- (FBBezierGraph *) unionWithBezierGraph:(FBBezierGraph *)graph;
- (FBBezierGraph *) intersectWithBezierGraph:(FBBezierGraph *)graph;
- (FBBezierGraph *) differenceWithBezierGraph:(FBBezierGraph *)graph;
- (FBBezierGraph *) xorWithBezierGraph:(FBBezierGraph *)graph;

- (CGPathRef) path;

@property (readonly) NSArray* contours;
@property (readonly) CGRect bounds;

- (FBCurveLocation *) closestLocationToPoint:(CGPoint)point;

- (void) debuggingInsertCrossingsForUnionWithBezierGraph:(FBBezierGraph *)otherGraph;
- (void) debuggingInsertCrossingsForIntersectWithBezierGraph:(FBBezierGraph *)otherGraph;
- (void) debuggingInsertCrossingsForDifferenceWithBezierGraph:(FBBezierGraph *)otherGraph;
- (void) debuggingInsertIntersectionsWithBezierGraph:(FBBezierGraph *)otherGraph;
- (CGPathRef) debugPathForContainmentOfContour:(FBBezierContour *)contour;
- (CGPathRef) debugPathForContainmentOfContour:(FBBezierContour *)testContour transform:(CGAffineTransform)transform;
- (CGPathRef) debugPathForJointsOfContour:(FBBezierContour *)testContour;

@end
