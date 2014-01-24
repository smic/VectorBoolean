//
//  FBContourOverlap.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 11/7/12.
//  Copyright (c) 2012 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBBezierContour, FBBezierCurve, FBBezierIntersectRange, FBEdgeCrossing;

@interface FBEdgeOverlap : NSObject {
    FBBezierCurve *_edge1;
    FBBezierCurve *_edge2;
    FBBezierIntersectRange *_range;
}

@property (readonly) FBBezierIntersectRange *range;

@end

@interface FBEdgeOverlapRun : NSObject {
    NSMutableArray *_overlaps;
}

@property (readonly) NSArray *overlaps;

- (BOOL) isCrossing;
- (void) addCrossings;

@end

@interface FBContourOverlap : NSObject {
    NSMutableArray *_runs;
}

+ (id) contourOverlap;

@property (readonly) FBBezierContour *contour1;
@property (readonly) FBBezierContour *contour2;

- (void) addOverlap:(FBBezierIntersectRange *)range forEdge1:(FBBezierCurve *)edge1 edge2:(FBBezierCurve *)edge2;
- (void) runsWithBlock:(void (^)(FBEdgeOverlapRun *run, BOOL *stop))block;

- (void) reset;

- (BOOL) isComplete;
- (BOOL) isEmpty;

- (BOOL) isBetweenContour:(FBBezierContour *)contour1 andContour:(FBBezierContour *)contour2;
- (BOOL) doesContainCrossing:(FBEdgeCrossing *)crossing;
- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge;

@end
