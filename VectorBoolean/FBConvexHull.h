//
//  FBConvexHull.h
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void FBConvexHullBuildFromPoints(NSPoint points[4], NSPoint *results, NSUInteger *outLength);