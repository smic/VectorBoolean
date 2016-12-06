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
    CGPoint endPoint1;
    CGPoint controlPoint1;
    CGPoint controlPoint2;
    CGPoint endPoint2;
	BOOL isStraightLine;		// GPC: flag when curve came from a straight line segment
    CGFloat length; // cached value
    CGRect bounds; // cached value
    BOOL isPoint; // cached value
    CGRect boundingRect; // cached value
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

+ (instancetype) bezierCurveWithLineStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;
+ (instancetype) bezierCurveWithEndPoint1:(CGPoint)endPoint1 controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 endPoint2:(CGPoint)endPoint2;

- (instancetype) initWithEndPoint1:(CGPoint)endPoint1 controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 endPoint2:(CGPoint)endPoint2 contour:(FBBezierContour *)contour;
- (instancetype) initWithLineStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint contour:(FBBezierContour *)contour;

@property (readonly) CGPoint endPoint1;
@property (readonly) CGPoint controlPoint1;
@property (readonly) CGPoint controlPoint2;
@property (readonly) CGPoint endPoint2;
@property (readonly) BOOL isStraightLine;
@property (readonly) CGRect bounds;
@property (readonly) CGRect boundingRect;
@property (readonly, getter = isPoint) BOOL point;

- (BOOL) doesHaveIntersectionsWithBezierCurve:(FBBezierCurve *)curve;
- (void) intersectionsWithBezierCurve:(FBBezierCurve *)curve overlapRange:(FBBezierIntersectRange **)intersectRange withBlock:(FBCurveIntersectionBlock)block;

- (CGPoint) pointAtParameter:(CGFloat)parameter leftBezierCurve:(FBBezierCurve **)leftBezierCurve rightBezierCurve:(FBBezierCurve **)rightBezierCurve;
- (FBBezierCurve *) subcurveWithRange:(FBRange)range;
- (void) splitSubcurvesWithRange:(FBRange)range left:(FBBezierCurve **)leftCurve middle:(FBBezierCurve **)middleCurve right:(FBBezierCurve **)rightCurve;

- (CGFloat) lengthAtParameter:(CGFloat)parameter;
@property (nonatomic, readonly) CGFloat length;

- (CGPoint) pointFromRightOffset:(CGFloat)offset;
- (CGPoint) pointFromLeftOffset:(CGFloat)offset;

- (CGPoint) tangentFromRightOffset:(CGFloat)offset;
- (CGPoint) tangentFromLeftOffset:(CGFloat)offset;

- (FBBezierCurveLocation) closestLocationToPoint:(CGPoint)point;

@property (nonatomic, readonly, strong) FBBezierCurve *reversedCurve;	// GPC: added

@property (nonatomic, readonly, copy) NSBezierPath *bezierPath;

- (FBBezierCurve *) clone;

@end
