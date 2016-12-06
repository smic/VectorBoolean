//
//  FBNormalizedLine.m
//  VectorBoolean
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import "FBNormalizedLine.h"

//////////////////////////////////////////////////////////////////////////////////
// Normalized lines
//

// Create a normalized line such that computing the distance from it is quick.
//  See:    http://softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm#Distance%20to%20an%20Infinite%20Line
//          http://www.cs.mtu.edu/~shene/COURSES/cs3621/NOTES/geometry/basic.html
//
FBNormalizedLine FBNormalizedLineMake(CGPoint point1, CGPoint point2)
{
    FBNormalizedLine line = { point1.y - point2.y, point2.x - point1.x, point1.x * point2.y - point2.x * point1.y };
    CGFloat distance = sqrt(line.b * line.b + line.a * line.a);
	
	// GPC: prevent divide-by-zero from putting NaNs into the values which cause trouble further on. I'm not sure
	// what cases trigger this, but sometimes point1 == point2 so distance is 0.
	if( distance != 0.0 ) {
		line.a /= distance;
		line.b /= distance;
		line.c /= distance;
	} else
		line.a = line.b = line.c = 0;
    
    return line;
}

FBNormalizedLine FBNormalizedLineMakeWithCoefficients(CGFloat a, CGFloat b, CGFloat c)
{
    FBNormalizedLine line = { a, b, c };
    return line;
}

FBNormalizedLine FBNormalizedLineOffset(FBNormalizedLine line, CGFloat offset)
{
    line.c += offset;
    return line;
}

CGFloat FBNormalizedLineDistanceFromPoint(FBNormalizedLine line, CGPoint point)
{
    return line.a * point.x + line.b * point.y + line.c;
}

CGPoint FBNormalizedLineIntersection(FBNormalizedLine line1, FBNormalizedLine line2)
{
    CGFloat denominator = line1.a * line2.b - line2.a * line1.b;
    return CGPointMake((line1.b * line2.c - line2.b * line1.c) / denominator, (line1.a * line2.c - line2.a * line1.c) / denominator);
}
