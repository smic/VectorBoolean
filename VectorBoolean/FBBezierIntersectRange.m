//
//  FBBezierIntersectRange.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 11/6/12.
//  Copyright (c) 2012 Fortunate Bear, LLC. All rights reserved.
//

#import "FBBezierIntersectRange.h"
#import "FBBezierCurve.h"
#import "FBBezierIntersection.h"

extern const CGFloat FBParameterCloseThreshold;

@interface FBBezierIntersectRange () 

- (void) computeCurve1;
- (void) computeCurve2;
- (void) clearCache;

@end

@implementation FBBezierIntersectRange

@synthesize curve1=_curve1;
@synthesize parameterRange1=_parameterRange1;
@synthesize curve2=_curve2;
@synthesize parameterRange2=_parameterRange2;
@synthesize reversed=_reversed;

+ (id) intersectRangeWithCurve1:(FBBezierCurve *)curve1 parameterRange1:(FBRange)parameterRange1 curve2:(FBBezierCurve *)curve2 parameterRange2:(FBRange)parameterRange2 reversed:(BOOL)reversed
{
    return [[FBBezierIntersectRange alloc] initWithCurve1:curve1 parameterRange1:parameterRange1 curve2:curve2 parameterRange2:parameterRange2 reversed:reversed];
}

- (id) initWithCurve1:(FBBezierCurve *)curve1 parameterRange1:(FBRange)parameterRange1 curve2:(FBBezierCurve *)curve2 parameterRange2:(FBRange)parameterRange2 reversed:(BOOL)reversed
{
    self = [super init];
    if ( self != nil ) {
        _curve1 = curve1;
        _parameterRange1 = parameterRange1;
        _curve2 = curve2;
        _parameterRange2 = parameterRange2;
        _reversed = reversed;
        _needToComputeCurve1 = YES;
        _needToComputeCurve2 = YES;
    }
    return self;
}


- (FBBezierCurve *) curve1LeftBezier
{
    [self computeCurve1];
    return _curve1LeftBezier;
}

- (FBBezierCurve *) curve1OverlappingBezier
{
    [self computeCurve1];
    return _curve1MiddleBezier;
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

- (FBBezierCurve *) curve2OverlappingBezier
{
    [self computeCurve2];
    return _curve2MiddleBezier;
}

- (FBBezierCurve *) curve2RightBezier
{
    [self computeCurve2];
    return _curve2RightBezier;
}

- (void) computeCurve1
{
    if ( !_needToComputeCurve1 )
        return;
	
	FBBezierCurve *curve1LeftBezier;
	FBBezierCurve *curve1MiddleBezier;
	FBBezierCurve *curve1RightBezier;
    [_curve1 splitSubcurvesWithRange:_parameterRange1 left:&curve1LeftBezier middle:&curve1MiddleBezier right:&curve1RightBezier];
	_curve1LeftBezier = curve1LeftBezier;
	_curve1MiddleBezier = curve1MiddleBezier;
	_curve1RightBezier = curve1RightBezier;
	
    _needToComputeCurve1 = NO;
}

- (void) computeCurve2
{
    if ( !_needToComputeCurve2 )
        return;
	
	FBBezierCurve *curve2LeftBezier;
	FBBezierCurve *curve2MiddleBezier;
	FBBezierCurve *curve2RightBezier;
    [_curve2 splitSubcurvesWithRange:_parameterRange2 left:&curve2LeftBezier middle:&curve2MiddleBezier right:&curve2RightBezier];
	_curve2LeftBezier = curve2LeftBezier;
	_curve2MiddleBezier = curve2MiddleBezier;
	_curve2RightBezier = curve2RightBezier;
	
    _needToComputeCurve2 = NO;
}

- (BOOL) isAtStartOfCurve1
{
    return FBAreValuesCloseWithOptions(_parameterRange1.minimum, 0.0, FBParameterCloseThreshold);
}

- (BOOL) isAtStopOfCurve1
{
    return FBAreValuesCloseWithOptions(_parameterRange1.maximum, 1.0, FBParameterCloseThreshold);
}

- (BOOL) isAtStartOfCurve2
{
    return FBAreValuesCloseWithOptions(_parameterRange2.minimum, 0.0, FBParameterCloseThreshold);
}

- (BOOL) isAtStopOfCurve2
{
    return FBAreValuesCloseWithOptions(_parameterRange2.maximum, 1.0, FBParameterCloseThreshold);
}

- (FBBezierIntersection *) middleIntersection
{
    return [FBBezierIntersection intersectionWithCurve1:_curve1 parameter1:(_parameterRange1.minimum + _parameterRange1.maximum) / 2.0 curve2:_curve2 parameter2:(_parameterRange2.minimum + _parameterRange2.maximum) / 2.0];    
}

- (void) merge:(FBBezierIntersectRange *)other
{
    // We assume the caller already knows we're talking about the same curves
    _parameterRange1 = FBRangeUnion(_parameterRange1, other->_parameterRange1);
    _parameterRange2 = FBRangeUnion(_parameterRange2, other->_parameterRange2);
    
    [self clearCache];
}

- (void) clearCache
{
    _needToComputeCurve1 = YES;
    _needToComputeCurve2 = YES;
    _curve1LeftBezier = nil;
    _curve1MiddleBezier = nil;
    _curve1RightBezier = nil;
    _curve2LeftBezier = nil;
    _curve2MiddleBezier = nil;
    _curve2RightBezier = nil;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: param1 = (%f, %f), param2 = (%f, %f)>", 
            NSStringFromClass([self class]),
            self.parameterRange1.minimum, self.parameterRange1.maximum, self.parameterRange2.minimum, self.parameterRange2.maximum];
}


@end
