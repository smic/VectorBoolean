//
//  FBCurveLocation.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/18/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//

#import "FBCurveLocation.h"

@implementation FBCurveLocation

@synthesize graph=_graph;
@synthesize contour=_contour;
@synthesize edge=_edge;
@synthesize parameter=_parameter;
@synthesize distance=_distance;

+ (id) curveLocationWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance
{
    return [[[FBCurveLocation alloc] initWithEdge:edge parameter:parameter distance:distance] autorelease];
}

- (id) initWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance
{
    self = [super init];
    if ( self != nil ) {
        _edge = [edge retain];
        _parameter = parameter;
        _distance = distance;
    }
    return self;
}

- (void) dealloc
{
    [_graph release];
    [_contour release];
    [_edge release];
    [super dealloc];
}


@end
