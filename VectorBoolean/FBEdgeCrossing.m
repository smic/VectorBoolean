//
//  FBEdgeCrossing.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "FBEdgeCrossing.h"
#import "FBBezierCurve.h"
#import "FBBezierCurve+Edge.h"
#import "FBBezierIntersection.h"

@implementation FBEdgeCrossing

@synthesize edge=_edge;
@synthesize counterpart=_counterpart;
@synthesize entry=_entry;
@synthesize processed=_processed;
@synthesize selfCrossing=_selfCrossing;
@synthesize index=_index;
@synthesize fromCrossingOverlap=_fromCrossingOverlap;

+ (id) crossingWithIntersection:(FBBezierIntersection *)intersection
{
    return [[FBEdgeCrossing alloc] initWithIntersection:intersection];
}

- (id) initWithIntersection:(FBBezierIntersection *)intersection
{
    self = [super init];
    
    if ( self != nil ) {
        _intersection = intersection;
    }
    
    return self;
}


- (void) removeFromEdge
{
    [_edge removeCrossing:self];
}

- (CGFloat) order
{
    return self.parameter;
}

- (FBEdgeCrossing *) next
{
    return [self.edge nextCrossing:self];
}

- (FBEdgeCrossing *) previous
{
    return [self.edge previousCrossing:self];
}

- (FBEdgeCrossing *) nextNonself
{
    FBEdgeCrossing *next = self.next;
    while ( next != nil && next.isSelfCrossing )
        next = next.next;
    return next;
}

- (FBEdgeCrossing *) previousNonself
{
    FBEdgeCrossing *previous = self.previous;
    while ( previous != nil && previous.isSelfCrossing )
        previous = previous.previous;
    return previous;
}

- (CGFloat) parameter
{
    if ( self.edge == _intersection.curve1 )
        return _intersection.parameter1;
    
    return _intersection.parameter2;
}

- (NSPoint) location
{
    return _intersection.location;
}

- (FBBezierCurve *) curve
{
    return self.edge;
}

- (FBBezierCurve *) leftCurve
{
    if ( self.isAtStart )
        return nil;
    
    if ( self.edge == _intersection.curve1 )
        return _intersection.curve1LeftBezier;
    
    return _intersection.curve2LeftBezier;
}

- (FBBezierCurve *) rightCurve
{
    if ( self.isAtEnd )
        return nil;
    
    if ( self.edge == _intersection.curve1 )
        return _intersection.curve1RightBezier;
    
    return _intersection.curve2RightBezier;
}

- (BOOL) isAtStart
{
    if ( self.edge == _intersection.curve1 )
        return _intersection.isAtStartOfCurve1;
    
    return _intersection.isAtStartOfCurve2;
}

- (BOOL) isAtEnd
{
    if ( self.edge == _intersection.curve1 )
        return _intersection.isAtStopOfCurve1;
    
    return _intersection.isAtStopOfCurve2;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: isEntry = %@, isProcessed = %@, isSelfIntersecting = %@, intersection = %@>", 
            NSStringFromClass([self class]),
            _entry ? @"yes" : @"no",
            _processed ? @"yes" : @"no",
            _selfCrossing ? @"yes" : @"no",
            _intersection.description
            ];
}

@end
