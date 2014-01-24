//
//  FBCurveLocation.h
//  VectorBoolean
//
//  Created by Andrew Finnell on 6/18/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBBezierCurve;
@class FBBezierContour;
@class FBBezierGraph;

@interface FBCurveLocation : NSObject {
    FBBezierGraph *_graph;
    FBBezierContour *_contour;
    FBBezierCurve *_edge;
    CGFloat _parameter;
    CGFloat _distance;
}

+ (id) curveLocationWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance;
- (id) initWithEdge:(FBBezierCurve *)edge parameter:(CGFloat)parameter distance:(CGFloat)distance;

@property (retain) FBBezierGraph *graph;
@property (retain) FBBezierContour *contour;
@property (readonly) FBBezierCurve *edge;
@property (readonly) CGFloat parameter;
@property (readonly) CGFloat distance;

@end
