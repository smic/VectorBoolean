//
//  FBBezierIntersection.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/6/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierIntersection.h"
#import "FBBezierCurve.h"
#import "FBGeometry.h"

static const CGFloat FBPointCloseThreshold = 1e-7;
const CGFloat FBParameterCloseThreshold = 1e-4;

@interface FBBezierIntersection ()

- (void) computeCurve1;
- (void) computeCurve2;

@end

@implementation FBBezierIntersection

@synthesize curve1=_curve1;
@synthesize parameter1=_parameter1;
@synthesize curve2=_curve2;
@synthesize parameter2=_parameter2;

+ (id) intersectionWithCurve1:(FBBezierCurve *)curve1 parameter1:(CGFloat)parameter1 curve2:(FBBezierCurve *)curve2 parameter2:(CGFloat)parameter2
{
    return [[FBBezierIntersection alloc] initWithCurve1:curve1 parameter1:parameter1 curve2:curve2 parameter2:parameter2];
}

- (id) initWithCurve1:(FBBezierCurve *)curve1 parameter1:(CGFloat)parameter1 curve2:(FBBezierCurve *)curve2 parameter2:(CGFloat)parameter2
{
    self = [super init];
    
    if ( self != nil ) {
        _curve1 = curve1;
        _parameter1 = parameter1;
        _curve2 = curve2;
        _parameter2 = parameter2;
        _needToComputeCurve1 = YES;
        _needToComputeCurve2 = YES;
    }
    
    return self;
}


- (CGPoint) location
{
    [self computeCurve1];
    return _location;
}

- (BOOL) isTangent
{
    // If we're at the end of a curve, it's not tangent, so skip all the calculations
    if ( self.isAtEndPointOfCurve )
        return NO;
    
    [self computeCurve1];
    [self computeCurve2];

    
    // Compute the tangents at the intersection. 
    CGPoint curve1LeftTangent = FBNormalizePoint(FBSubtractPoint(_curve1LeftBezier.controlPoint2, _curve1LeftBezier.endPoint2));
    CGPoint curve1RightTangent = FBNormalizePoint(FBSubtractPoint(_curve1RightBezier.controlPoint1, _curve1RightBezier.endPoint1));
    CGPoint curve2LeftTangent = FBNormalizePoint(FBSubtractPoint(_curve2LeftBezier.controlPoint2, _curve2LeftBezier.endPoint2));
    CGPoint curve2RightTangent = FBNormalizePoint(FBSubtractPoint(_curve2RightBezier.controlPoint1, _curve2RightBezier.endPoint1));
        
    // See if the tangents are the same. If so, then we're tangent at the intersection point
    return FBArePointsCloseWithOptions(curve1LeftTangent, curve2LeftTangent, FBPointCloseThreshold) || FBArePointsCloseWithOptions(curve1LeftTangent, curve2RightTangent, FBPointCloseThreshold) || FBArePointsCloseWithOptions(curve1RightTangent, curve2LeftTangent, FBPointCloseThreshold) || FBArePointsCloseWithOptions(curve1RightTangent, curve2RightTangent, FBPointCloseThreshold);
}

- (FBBezierCurve *) curve1LeftBezier
{
    [self computeCurve1];
    return _curve1LeftBezier;
}

- (FBBezierCurve *) curve1RightBezier
{
    [self computeCurve1];
    return _curve1RightBezier;
}

- (FBBezierCurve *) curve2LeftBezier
{
    [self computeCurve2];
    return _curve2LeftBezier;
}

- (FBBezierCurve *) curve2RightBezier
{
    [self computeCurve2];
    return _curve2RightBezier;
}

- (BOOL) isAtStartOfCurve1
{
    return FBAreValuesCloseWithOptions(_parameter1, 0.0, FBParameterCloseThreshold) || _curve1.isPoint;
}

- (BOOL) isAtStopOfCurve1
{
    return FBAreValuesCloseWithOptions(_parameter1, 1.0, FBParameterCloseThreshold) || _curve1.isPoint;
}

- (BOOL) isAtEndPointOfCurve1
{
    return self.isAtStartOfCurve1 || self.isAtStopOfCurve1;
}

- (BOOL) isAtStartOfCurve2
{
    return FBAreValuesCloseWithOptions(_parameter2, 0.0, FBParameterCloseThreshold) || _curve2.isPoint;
}

- (BOOL) isAtStopOfCurve2
{
    return FBAreValuesCloseWithOptions(_parameter2, 1.0, FBParameterCloseThreshold) || _curve2.isPoint;
}

- (BOOL) isAtEndPointOfCurve2
{
    return self.isAtStartOfCurve2 || self.isAtStopOfCurve2;
}

- (BOOL) isAtEndPointOfCurve
{
    return self.isAtEndPointOfCurve1 || self.isAtEndPointOfCurve2;
}

- (void) computeCurve1
{
    if ( !_needToComputeCurve1 )
        return;
	
	FBBezierCurve *curve1LeftBezier;
	FBBezierCurve *curve1RightBezier;
    _location = [_curve1 pointAtParameter:_parameter1 leftBezierCurve:&curve1LeftBezier rightBezierCurve:&curve1RightBezier];
    _curve1LeftBezier = curve1LeftBezier;
    _curve1RightBezier = curve1RightBezier;
    
    _needToComputeCurve1 = NO;
}

- (void) computeCurve2
{
    if ( !_needToComputeCurve2 )
        return;
	
	FBBezierCurve *curve2LeftBezier;
	FBBezierCurve *curve2RightBezier;
    [_curve2 pointAtParameter:_parameter2 leftBezierCurve:&curve2LeftBezier rightBezierCurve:&curve2RightBezier];
    _curve2LeftBezier = curve2LeftBezier;
    _curve2RightBezier = curve2RightBezier;
    
    _needToComputeCurve2 = NO;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: location = (%f, %f), param1 = %f, param2 = %f, isTangent = %@>", 
            NSStringFromClass([self class]),
            self.location.x, self.location.y,
            self.parameter1, self.parameter2,
            self.isTangent ? @"yes" : @"no"];
}

@end
