//
//  AppDelegate.m
//  VectorBooleanDemo
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "CanvasView.h"

typedef NS_ENUM(NSUInteger, BooleanType) {
    BooleanTypeNone = 0,
    BooleanTypeUnion,
	BooleanTypeDifference,
    BooleanTypeIntersect,
    BooleanTypeXOR,
};

@interface AppDelegate ()

@property (nonatomic, weak) IBOutlet CanvasView *view;
@property (nonatomic, strong) CGPathRef path1 __attribute__((NSObject));
@property (nonatomic, strong) CGPathRef path2 __attribute__((NSObject));
@property (nonatomic) NSUInteger exampleIndex;
@property (nonatomic) BooleanType booleanType;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self updatePaths];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void)updatePaths {
    switch (self.exampleIndex) {
        case 0:
            [self addSomeOverlap];
            break;
            
        case 1:
            [self addCircleInRectangle];
            break;
            
        case 2:
            [self addRectangleInCircle];
            break;
            
        case 3:
            [self addCircleOnRectangle];
            break;
            
        case 4:
            [self addHoleyRectangleWithRectangle];
            break;
            
        case 5:
            [self addCircleOnTwoRectangles];
            break;
            
        case 6:
            [self addCircleOverlappingCircle];
            break;
            
        case 7:
            [self addComplexShapes];
            break;
            
        case 8:
            [self addComplexShapes2];
            break;
            
        case 9:
            [self addTriangleInsideRectangle];
            break;
            
        case 10:
            [self addDiamondOverlappingRectangle];
            break;
            
        case 11:
            [self addDiamondInsideRectangle];
            break;
            
        case 12:
            [self addNonOverlappingContours];
            break;
            
        case 13:
            [self addMoreNonOverlappingContours];
            break;
            
        case 14:
            [self addConcentricContours];
            break;
            
        case 15:
            [self addMoreConcentricContours];
            break;
            
        case 16:
            [self addOverlappingHole];
            break;
            
        case 17:
            [self addHoleOverlappingHole];
            break;
            
        case 18:
            [self addCurvyShapeOverlappingRectangle];
            break;
            
        default:
            break;
    }
    
    self.booleanType = BooleanTypeNone;
    [self upateView];
}

- (void)addSomeOverlap
{
    self.path1 = [self pathWithRectangle:CGRectMake(50, 50, 300, 200)];
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(355, 240) withRadius:125];
}

- (void)addCircleInRectangle
{
    self.path1 = [self pathWithRectangle:CGRectMake(50, 50, 300, 300)];
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(200, 200) withRadius:150];
}

- (void)addRectangleInCircle
{
    self.path1 = [self pathWithRectangle:CGRectMake(150, 150, 150, 150)];
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(200, 200) withRadius:185];
}

- (void)addCircleOnRectangle
{
    self.path1 = [self pathWithRectangle:CGRectMake(15, 15, 370, 370)];
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(200, 200) withRadius:185];
}

- (void)addHoleyRectangleWithRectangle
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(180, 5, 100, 400) toPath:path2];
    self.path2 = path2;
}

- (void)addCircleOnTwoRectangles
{
    CGMutablePathRef rectangles = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 5, 100, 400) toPath:rectangles];
    [self addRectangle:CGRectMake(350, 5, 100, 400) toPath:rectangles];
    self.path1 = rectangles;
    
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(200, 200) withRadius:185];
}

- (void)addCircleOverlappingCircle
{
    CGMutablePathRef circle = CGPathCreateMutable();
    [self addCircleAtPoint:CGPointMake(355, 240) withRadius:125 toPath:circle];
    self.path1 = circle;
    
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(210, 110) withRadius:100];
}

- (void)addComplexShapes
{
    CGMutablePathRef part1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:part1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:part1];
    
    CGPathRef part2 = [self pathWithRectangle:CGRectMake(180, 5, 100, 400)];
    
    CGPathRef allParts = CGPathUnion(part1, part2);
    CGPathRef intersectingParts = CGPathIntersect(part1, part2);
    
    self.path1 = allParts;
    self.path2 = intersectingParts;
}

- (void)addComplexShapes2
{
    CGMutablePathRef part1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 5, 100, 400) toPath:part1];
    [self addRectangle:CGRectMake(350, 5, 100, 400) toPath:part1];
    
    CGMutablePathRef part2 = CGPathCreateMutable();
    [self addCircleAtPoint:CGPointMake(200, 200) withRadius:185 toPath:part2];
    
	CGPathRef allParts = CGPathUnion(part1, part2);
	CGPathRef intersectingParts = CGPathIntersect(part1, part2);
	
    self.path1 = allParts;
    self.path2 = intersectingParts;
}

- (void)addTriangleInsideRectangle
{
    self.path1 = [self pathWithRectangle:CGRectMake(100, 100, 300, 300)];
    self.path2 = [self pathWithTriangle:CGPointMake(100, 400) point2:CGPointMake(400, 400) point3:CGPointMake(250, 250)];
}

- (void)addDiamondOverlappingRectangle
{
    self.path1 = [self pathWithRectangle:CGRectMake(50, 50, 200, 200)];
    self.path2 = [self pathWithQuadrangle:CGPointMake(50, 250) point2:CGPointMake(150, 400) point3:CGPointMake(250, 250) point4:CGPointMake(150, 100)];
}

- (void)addDiamondInsideRectangle
{
    self.path1 = [self pathWithRectangle:CGRectMake(100, 100, 300, 300)];
    self.path2 = [self pathWithQuadrangle:CGPointMake(100, 250) point2:CGPointMake(250, 400) point3:CGPointMake(400, 250) point4:CGPointMake(250, 100)];
}

- (void)addNonOverlappingContours
{
    self.path1 = [self pathWithRectangle:CGRectMake(100, 200, 200, 200)];
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    [self addCircleAtPoint:CGPointMake(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:CGPointMake(200, 95) withRadius:85 toPath:path2];
    self.path2 = path2;
}

- (void)addMoreNonOverlappingContours
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(100, 200, 200, 200) toPath:path1];
    [self addRectangle:CGRectMake(175, 70, 50, 50) toPath:path1];
    self.path1 = path1;
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    [self addCircleAtPoint:CGPointMake(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:CGPointMake(200, 95) withRadius:85 toPath:path2];
    self.path2 = path2;
}

- (void)addConcentricContours
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(210, 200) withRadius:140];
}

- (void)addMoreConcentricContours
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    self.path2 = [self pathWithCircleAtPoint:CGPointMake(210, 200) withRadius:70];
}

- (void)addOverlappingHole
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    [self addCircleAtPoint:CGPointMake(180, 180) withRadius:125 toPath:path2];
    self.path2 = path2;
}

- (void)addHoleOverlappingHole
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:CGPointMake(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    CGMutablePathRef path2 = CGPathCreateMutable();
    [self addRectangle:CGRectMake(225, 65, 160, 160) toPath:path2];
    [self addCircleAtPoint:CGPointMake(305, 145) withRadius:65 toPath:path2];
    self.path2 = path2;
}

- (void)addCurvyShapeOverlappingRectangle
{
    CGMutablePathRef path1 = CGPathCreateMutable();
    CGFloat top = 65.0 + 160.0 / 3.0;
	CGPathMoveToPoint(path1, NULL, 40, top);
	CGPathAddLineToPoint(path1, NULL, 410, top);
	CGPathAddLineToPoint(path1, NULL, 410, 50);
	CGPathAddLineToPoint(path1, NULL, 40, 50);
	CGPathAddLineToPoint(path1, NULL, 40, top);
    self.path1 = path1;
    
    CGMutablePathRef path2 = CGPathCreateMutable();
	CGPathMoveToPoint(path1, NULL, 335.000000, 203.000000);
	CGPathAddCurveToPoint(path2, NULL, 335.000000, 202.000000, 335.000000, 153.000000, 335.000000, 200.000000);
	CGPathAddCurveToPoint(path2, NULL, 335.000000, 153.000000, 309.000000, 111.000000, 270.000000, 90.000000);
	CGPathAddCurveToPoint(path2, NULL, 252.000000, 102.000000, 240.000000, 122.000000, 240.000000, 145.000000);
	CGPathAddCurveToPoint(path2, NULL, 240.000000, 181.000000, 269.000000, 210.000000, 305.000000, 210.000000);
	CGPathAddCurveToPoint(path2, NULL, 316.000000, 210.000000, 326.000000, 207.000000, 335.000000, 203.000000);
    self.path2 = path2;
}

- (CGPathRef)pathWithRectangle:(CGRect)rect
{
    CGMutablePathRef rectangle = CGPathCreateMutable();
    [self addRectangle:rect toPath:rectangle];
    return rectangle;
}

- (CGPathRef)pathWithCircleAtPoint:(CGPoint)center withRadius:(CGFloat)radius
{
    CGMutablePathRef circle = CGPathCreateMutable();
    [self addCircleAtPoint:center withRadius:radius toPath:circle];
    return circle;
}

- (CGPathRef)pathWithTriangle:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3
{
    CGMutablePathRef triangle = CGPathCreateMutable();
    [self addTriangle:point1 point2:point2 point3:point3 toPath:triangle];
    return triangle;
}

- (CGPathRef)pathWithQuadrangle:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3 point4:(CGPoint)point4
{
    CGMutablePathRef quandrangle = CGPathCreateMutable();
    [self addQuadrangle:point1 point2:point2 point3:point3 point4:point4 toPath:quandrangle];
    return quandrangle;
}

- (void)addRectangle:(CGRect)rect toPath:(CGMutablePathRef)path
{
	CGPathAddRect(path, NULL, rect);
}

- (void)addCircleAtPoint:(CGPoint)center withRadius:(CGFloat)radius toPath:(CGMutablePathRef)circle
{
    static const CGFloat FBMagicNumber = 0.55228475;
    CGFloat controlPointLength = radius * FBMagicNumber;
	CGPathMoveToPoint(circle, NULL, center.x - radius, center.y);
	CGPathAddCurveToPoint(circle, NULL, center.x - radius, center.y + controlPointLength, center.x - controlPointLength, center.y + radius, center.x, center.y + radius);
	CGPathAddCurveToPoint(circle, NULL, center.x + controlPointLength, center.y + radius,center.x + radius, center.y + controlPointLength, center.x + radius, center.y);
	CGPathAddCurveToPoint(circle, NULL, center.x + radius, center.y - controlPointLength, center.x + controlPointLength, center.y - radius, center.x, center.y - radius);
	CGPathAddCurveToPoint(circle, NULL, center.x - controlPointLength, center.y - radius, center.x - radius, center.y - controlPointLength, center.x - radius, center.y);
}

- (void)addTriangle:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3 toPath:(CGMutablePathRef)path
{
	CGPathMoveToPoint(path, NULL, point1.x, point1.y);
	CGPathAddLineToPoint(path, NULL, point2.x, point2.y);
	CGPathAddLineToPoint(path, NULL, point3.x, point3.y);
	CGPathAddLineToPoint(path, NULL, point1.x, point1.y);
}

- (void)addQuadrangle:(CGPoint)point1 point2:(CGPoint)point2 point3:(CGPoint)point3 point4:(CGPoint)point4 toPath:(CGMutablePathRef)path
{
	CGPathMoveToPoint(path, NULL, point1.x, point1.y);
	CGPathAddLineToPoint(path, NULL, point2.x, point2.y);
	CGPathAddLineToPoint(path, NULL, point3.x, point3.y);
	CGPathAddLineToPoint(path, NULL, point4.x, point4.y);
	CGPathAddLineToPoint(path, NULL, point1.x, point1.y);
}

- (void)upateView {
    [self.view clear];
    switch (self.booleanType) {
        case BooleanTypeNone: {
            [self.view addPath:self.path1 withColor:[NSColor blueColor]];
            [self.view addPath:self.path2 withColor:[NSColor redColor]];
        } break;
            
        case BooleanTypeUnion: {
			NSLog(@"Union");
            CGPathRef result = CGPathUnion(self.path1, self.path2);
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeDifference: {
			NSLog(@"Difference");
            CGPathRef result = CGPathDifference(self.path1, self.path2);
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeIntersect: {
			NSLog(@"Intersect");
            CGPathRef result = CGPathIntersect(self.path1, self.path2);
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeXOR: {
			NSLog(@"XOR");
            CGPathRef result = CGPathXOR(self.path1, self.path2);
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
            
        default:
            break;
    }
    [self.view setNeedsDisplay:YES];
}

- (IBAction)onChooseExample:(id)sender {
    [self updatePaths];
}

- (IBAction)onChooseNextExample:(id)sender {
	NSUInteger exampleIndex = self.exampleIndex;
	NSLog(@"BEFORE: %lu", exampleIndex);
	NSLog(@"tag: %li", [sender selectedSegment]);
	if ([sender selectedSegment] == 0) {
		if (exampleIndex == 0) {
			self.exampleIndex = 18;
		} else {
			self.exampleIndex = exampleIndex - 1;
		}
	} else {
		if (exampleIndex == 18) {
			self.exampleIndex = 0;
		} else {
			self.exampleIndex = exampleIndex + 1;
		}
	}
	[self updatePaths];
	NSLog(@"AFTER: %lu", self.exampleIndex);
}

- (IBAction)onChooseBooleanType:(id)sender {
    [self upateView];
}

- (IBAction)onShowPoints:(id)sender
{
    self.view.showPoints = !self.view.showPoints;
    [self.view setNeedsDisplay:YES];
}

- (IBAction)onShowIntersections:(id)sender
{
    self.view.showIntersections = !self.view.showIntersections;
    [self.view setNeedsDisplay:YES];
}

@end
