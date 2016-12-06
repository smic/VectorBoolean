//
//  FBEdgeCrossing.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBBezierIntersection;
@class FBBezierCurve;

// FBEdgeCrossing is used by the boolean operations code to hold data about
//  where two edges actually cross (as opposed to just intersect). The main
//  piece of data is the intersection, but it also holds a pointer to the
//  crossing's counterpart in the other FBBezierGraph
@interface FBEdgeCrossing : NSObject {
    FBBezierIntersection *_intersection;
    __weak FBBezierCurve *_edge;
    __weak FBEdgeCrossing *_counterpart;
    BOOL _fromCrossingOverlap;
    BOOL _entry;
    BOOL _processed;
    BOOL _selfCrossing;
    NSUInteger _index;
}

+ (id) crossingWithIntersection:(FBBezierIntersection *)intersection;
- (id) initWithIntersection:(FBBezierIntersection *)intersection;

- (void) removeFromEdge;

@property (weak) FBBezierCurve *edge;
@property (weak) FBEdgeCrossing *counterpart;
@property (readonly) CGFloat order;
@property (getter = isEntry) BOOL entry;
@property (getter = isProcessed) BOOL processed;
@property (getter = isSelfCrossing) BOOL selfCrossing;
@property BOOL fromCrossingOverlap;
@property NSUInteger index;

// An easy way to iterate crossings. It doesn't wrap when it reaches the end.
@property (weak, readonly) FBEdgeCrossing *next;
@property (weak, readonly) FBEdgeCrossing *previous;
@property (weak, readonly) FBEdgeCrossing *nextNonself;
@property (weak, readonly) FBEdgeCrossing *previousNonself;

// These properties pass through to the underlying intersection
@property (readonly) CGFloat parameter;
@property (weak, readonly) FBBezierCurve *curve;
@property (weak, readonly) FBBezierCurve *leftCurve;
@property (weak, readonly) FBBezierCurve *rightCurve;
@property (readonly, getter = isAtStart) BOOL atStart;
@property (readonly, getter = isAtEnd) BOOL atEnd;
@property (readonly) CGPoint location;

@end
