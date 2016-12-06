//
//  CGPath+Boolean.m
//  VectorBoolean
//
//  Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//

#import "CGPath+Boolean.h"
#import "CGPath+Utilities.h"
#import "FBBezierGraph.h"

CGPathRef CGPathUnion(CGPathRef path1, CGPathRef path2) {
	FBBezierGraph *thisGraph = [FBBezierGraph bezierGraphWithPath:path1];
	FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithPath:path2];
	CGPathRef result = [[thisGraph unionWithBezierGraph:otherGraph] path];
	return result;
}

CGPathRef CGPathIntersect(CGPathRef path1, CGPathRef path2) {
	FBBezierGraph *thisGraph = [FBBezierGraph bezierGraphWithPath:path1];
	FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithPath:path2];
	CGPathRef result = [[thisGraph intersectWithBezierGraph:otherGraph] path];
	return result;
}

CGPathRef CGPathDifference(CGPathRef path1, CGPathRef path2) {
	FBBezierGraph *thisGraph = [FBBezierGraph bezierGraphWithPath:path1];
	FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithPath:path2];
	CGPathRef result = [[thisGraph differenceWithBezierGraph:otherGraph] path];
	return result;
}


CGPathRef CGPathXOR(CGPathRef path1, CGPathRef path2) {
	FBBezierGraph *thisGraph = [FBBezierGraph bezierGraphWithPath:path1];
	FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithPath:path2];
	CGPathRef result = [[thisGraph xorWithBezierGraph:otherGraph] path];
	return result;
}
