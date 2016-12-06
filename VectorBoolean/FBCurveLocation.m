//
//  FBCurveLocation.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/18/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//

#import "FBCurveLocation.h"
#import "FBBezierCurve.h"
#import "FBBezierContour.h"
#import "FBBezierGraph.h"


@implementation FBCurveLocation

@synthesize graph=_graph;
@synthesize contour=_contour;
@synthesize edge=_edge;
@synthesize parameter=_parameter;
@synthesize distance=_distance;

+ (id) curveLocationWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance
{
    return [[FBCurveLocation alloc] initWithEdge:edge parameter:parameter distance:distance];
}

- (id) initWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance
{
    self = [super init];
    if ( self != nil ) {
        _edge = edge;
        _parameter = parameter;
        _distance = distance;
    }
    return self;
}



@end
