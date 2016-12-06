//
//  FBBezierCurve.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/6/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBGeometry.h"

@class FBBezierIntersectRange, FBBezierIntersection, FBBezierContour;

typedef void (^FBCurveIntersectionBlock)(FBBezierIntersection *intersection, BOOL *stop);

typedef struct FBBezierCurveLocation {
    CGFloat parameter;
    CGFloat distance;
} FBBezierCurveLocation;

typedef struct FBBezierCurveData {
    NSPoint endPoint1;
    NSPoint controlPoint1;
    NSPoint controlPoint2;
    NSPoint endPoint2;
	BOOL isStraightLine;		// GPC: flag when curve came from a straight line segment
    CGFloat length; // cached value
    NSRect bounds; // cached value
    BOOL isPoint; // cached value
    NSRect boundingRect; // cached value
} FBBezierCurveData;

// FBBezierCurve is one cubic 2D bezier curve. It represents one segment of a bezier path, and is where
//  the intersection calculation happens
@interface FBBezierCurve : NSObject {
    FBBezierCurveData _data;
    
    NSMutableArray *_crossings; // sorted by parameter of the intersection
    FBBezierContour *_contour;
    NSUInteger _index;
    BOOL _startShared;
}

+ (NSArray *) bezierCurvesFromBezierPath:(NSBezierPath *)path;

+ (instancetype) bezierCurveWithLineStartPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint;
+ (instancetype) bezierCurveWithEndPoint1:(NSPoint)endPoint1 controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2 endPoint2:(NSPoint)endPoint2;

- (instancetype) initWithEndPoint1:(NSPoint)endPoint1 controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2 endPoint2:(NSPoint)endPoint2 contour:(FBBezierContour *)contour;
- (instancetype) initWithLineStartPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint contour:(FBBezierContour *)contour;

@property (readonly) NSPoint endPoint1;
@property (readonly) NSPoint controlPoint1;
@property (readonly) NSPoint controlPoint2;
@property (readonly) NSPoint endPoint2;
@property (readonly) BOOL isStraightLine;
@property (readonly) NSRect bounds;
@property (readonly) NSRect boundingRect;
@property (readonly, getter = isPoint) BOOL point;

- (BOOL) doesHaveIntersectionsWithBezierCurve:(FBBezierCurve *)curve;
- (void) intersectionsWithBezierCurve:(FBBezierCurve *)curve overlapRange:(FBBezierIntersectRange **)intersectRange withBlock:(FBCurveIntersectionBlock)block;

- (NSPoint) pointAtParameter:(CGFloat)parameter leftBezierCurve:(FBBezierCurve **)leftBezierCurve rightBezierCurve:(FBBezierCurve **)rightBezierCurve;
- (FBBezierCurve *) subcurveWithRange:(FBRange)range;
- (void) splitSubcurvesWithRange:(FBRange)range left:(FBBezierCurve **)leftCurve middle:(FBBezierCurve **)middleCurve right:(FBBezierCurve **)rightCurve;

- (CGFloat) lengthAtParameter:(CGFloat)parameter;
@property (nonatomic, readonly) CGFloat length;

- (NSPoint) pointFromRightOffset:(CGFloat)offset;
- (NSPoint) pointFromLeftOffset:(CGFloat)offset;

- (NSPoint) tangentFromRightOffset:(CGFloat)offset;
- (NSPoint) tangentFromLeftOffset:(CGFloat)offset;

- (FBBezierCurveLocation) closestLocationToPoint:(NSPoint)point;

@property (nonatomic, readonly, strong) FBBezierCurve *reversedCurve;	// GPC: added

@property (nonatomic, readonly, copy) NSBezierPath *bezierPath;

- (FBBezierCurve *) clone;

@end
