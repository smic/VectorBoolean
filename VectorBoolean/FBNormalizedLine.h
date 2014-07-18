//
//  FBNormalizedLine.h
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct FBNormalizedLine {
    CGFloat a; // * x +
    CGFloat b; // * y +
    CGFloat c; // constant
} FBNormalizedLine;

FBNormalizedLine FBNormalizedLineMake(NSPoint point1, NSPoint point2);
FBNormalizedLine FBNormalizedLineMakeWithCoefficients(CGFloat a, CGFloat b, CGFloat c);
FBNormalizedLine FBNormalizedLineOffset(FBNormalizedLine line, CGFloat offset);
CGFloat FBNormalizedLineDistanceFromPoint(FBNormalizedLine line, NSPoint point);
NSPoint FBNormalizedLineIntersection(FBNormalizedLine line1, FBNormalizedLine line2);