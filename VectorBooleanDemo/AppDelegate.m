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
    BooleanTypeSeparator,
    BooleanTypeUnion,
    BooleanTypeDifference,
    BooleanTypeIntersect,
    BooleanTypeXOR,
};

@interface AppDelegate ()

@property (nonatomic, weak) IBOutlet CanvasView *view;
@property (nonatomic, strong) NSBezierPath *path1;
@property (nonatomic, strong) NSBezierPath *path2;
@property (nonatomic) NSUInteger exampleIndex;
@property (nonatomic) BooleanType booleanType;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self updatePaths];
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
    self.path1 = [self pathWithRectangle:NSMakeRect(50, 50, 300, 200)];
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(355, 240) withRadius:125];
}

- (void)addCircleInRectangle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(50, 50, 350, 300)];
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:125];
}

- (void)addRectangleInCircle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(150, 150, 150, 150)];
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
}

- (void)addCircleOnRectangle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(15, 15, 370, 370)];
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
}

- (void)addHoleyRectangleWithRectangle
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(180, 5, 100, 400) toPath:path2];
    self.path2 = path2;
}

- (void)addCircleOnTwoRectangles
{
    NSBezierPath *rectangles = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 5, 100, 400) toPath:rectangles];
    [self addRectangle:NSMakeRect(350, 5, 100, 400) toPath:rectangles];
    self.path1 = rectangles;
    
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
}

- (void)addCircleOverlappingCircle
{
    NSBezierPath *circle = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(355, 240) withRadius:125 toPath:circle];
    self.path1 = circle;
    
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 110) withRadius:100];
}

- (void)addComplexShapes
{
    NSBezierPath *part1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:part1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:part1];
    
    NSBezierPath *part2 = [self pathWithRectangle:NSMakeRect(180, 5, 100, 400)];
    
    NSBezierPath *allParts = [part1 fb_union:part2];
    NSBezierPath *intersectingParts = [part1 fb_intersect:part2];
    
    self.path1 = allParts;
    self.path2 = intersectingParts;
}

- (void)addComplexShapes2
{
    NSBezierPath *part1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 5, 100, 400) toPath:part1];
    [self addRectangle:NSMakeRect(350, 5, 100, 400) toPath:part1];
    
    NSBezierPath *part2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 200) withRadius:185 toPath:part2];
    
    NSBezierPath *allParts = [part1 fb_union:part2];
    NSBezierPath *intersectingParts = [part1 fb_intersect:part2];
    
    self.path1 = allParts;
    self.path2 = intersectingParts;
}

- (void)addTriangleInsideRectangle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(100, 100, 300, 300)];
    self.path2 = [self pathWithTriangle:NSMakePoint(100, 400) point2:NSMakePoint(400, 400) point3:NSMakePoint(250, 250)];
}

- (void)addDiamondOverlappingRectangle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(50, 50, 200, 200)];
    self.path2 = [self pathWithQuadrangle:NSMakePoint(50, 250) point2:NSMakePoint(150, 400) point3:NSMakePoint(250, 250) point4:NSMakePoint(150, 100)];
}

- (void)addDiamondInsideRectangle
{
    self.path1 = [self pathWithRectangle:NSMakeRect(100, 100, 300, 300)];
    self.path2 = [self pathWithQuadrangle:NSMakePoint(100, 250) point2:NSMakePoint(250, 400) point3:NSMakePoint(400, 250) point4:NSMakePoint(250, 100)];
}

- (void)addNonOverlappingContours
{
    self.path1 = [self pathWithRectangle:NSMakeRect(100, 200, 200, 200)];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:NSMakePoint(200, 95) withRadius:85 toPath:path2];
    self.path2 = path2;
}

- (void)addMoreNonOverlappingContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(100, 200, 200, 200) toPath:path1];
    [self addRectangle:NSMakeRect(175, 70, 50, 50) toPath:path1];
    self.path1 = path1;
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:NSMakePoint(200, 95) withRadius:85 toPath:path2];
    self.path2 = path2;
}

- (void)addConcentricContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:140];
}

- (void)addMoreConcentricContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    self.path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:70];
}

- (void)addOverlappingHole
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(180, 180) withRadius:125 toPath:path2];
    self.path2 = path2;
}

- (void)addHoleOverlappingHole
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    self.path1 = path1;
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(225, 65, 160, 160) toPath:path2];
    [self addCircleAtPoint:NSMakePoint(305, 145) withRadius:65 toPath:path2];
    self.path2 = path2;
}

- (void)addCurvyShapeOverlappingRectangle
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    CGFloat top = 65.0 + 160.0 / 3.0;
    [path1 moveToPoint:NSMakePoint(40, top)];
    [path1 lineToPoint:NSMakePoint(410, top)];
    [path1 lineToPoint:NSMakePoint(410, 50)];
    [path1 lineToPoint:NSMakePoint(40, 50)];
    [path1 lineToPoint:NSMakePoint(40, top)];
    self.path1 = path1;
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [path2 moveToPoint:NSMakePoint(335.000000, 203.000000)];
    [path2 curveToPoint:NSMakePoint(335.000000, 200.000000) controlPoint1:NSMakePoint(335.000000, 202.000000) controlPoint2:NSMakePoint(335.000000, 201.000000)];
    [path2 curveToPoint:NSMakePoint(270.000000, 90.000000) controlPoint1:NSMakePoint(335.000000, 153.000000) controlPoint2:NSMakePoint(309.000000, 111.000000)];
    [path2 curveToPoint:NSMakePoint(240.000000, 145.000000) controlPoint1:NSMakePoint(252.000000, 102.000000) controlPoint2:NSMakePoint(240.000000, 122.000000)];
    [path2 curveToPoint:NSMakePoint(305.000000, 210.000000) controlPoint1:NSMakePoint(240.000000, 181.000000) controlPoint2:NSMakePoint(269.000000, 210.000000)];
    [path2 curveToPoint:NSMakePoint(335.000000, 203.000000) controlPoint1:NSMakePoint(316.000000, 210.000000) controlPoint2:NSMakePoint(326.000000, 207.000000)];
    self.path2 = path2;
}

- (NSBezierPath *)pathWithRectangle:(NSRect)rect
{
    NSBezierPath *rectangle = [NSBezierPath bezierPath];
    [self addRectangle:rect toPath:rectangle];
    return rectangle;
}

- (NSBezierPath *)pathWithCircleAtPoint:(NSPoint)center withRadius:(CGFloat)radius
{
    NSBezierPath *circle = [NSBezierPath bezierPath];
    [self addCircleAtPoint:center withRadius:radius toPath:circle];
    return circle;
}

- (NSBezierPath *)pathWithTriangle:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3
{
    NSBezierPath *triangle = [NSBezierPath bezierPath];
    [self addTriangle:point1 point2:point2 point3:point3 toPath:triangle];
    return triangle;
}

- (NSBezierPath *)pathWithQuadrangle:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3 point4:(NSPoint)point4
{
    NSBezierPath *quandrangle = [NSBezierPath bezierPath];
    [self addQuadrangle:point1 point2:point2 point3:point3 point4:point4 toPath:quandrangle];
    return quandrangle;
}

- (void)addRectangle:(NSRect)rect toPath:(NSBezierPath *)path
{
    [path appendBezierPathWithRect:rect];
}

- (void)addCircleAtPoint:(NSPoint)center withRadius:(CGFloat)radius toPath:(NSBezierPath *)circle
{
    static const CGFloat FBMagicNumber = 0.55228475;
    CGFloat controlPointLength = radius * FBMagicNumber;
    [circle moveToPoint:NSMakePoint(center.x - radius, center.y)];
    [circle curveToPoint:NSMakePoint(center.x, center.y + radius) controlPoint1:NSMakePoint(center.x - radius, center.y + controlPointLength) controlPoint2:NSMakePoint(center.x - controlPointLength, center.y + radius)];
    [circle curveToPoint:NSMakePoint(center.x + radius, center.y) controlPoint1:NSMakePoint(center.x + controlPointLength, center.y + radius) controlPoint2:NSMakePoint(center.x + radius, center.y + controlPointLength)];
    [circle curveToPoint:NSMakePoint(center.x, center.y - radius) controlPoint1:NSMakePoint(center.x + radius, center.y - controlPointLength) controlPoint2:NSMakePoint(center.x + controlPointLength, center.y - radius)];
    [circle curveToPoint:NSMakePoint(center.x - radius, center.y) controlPoint1:NSMakePoint(center.x - controlPointLength, center.y - radius) controlPoint2:NSMakePoint(center.x - radius, center.y - controlPointLength)];
}

- (void)addTriangle:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3 toPath:(NSBezierPath *)path
{
    [path moveToPoint:point1];
    [path lineToPoint:point2];
    [path lineToPoint:point3];
    [path lineToPoint:point1];
}

- (void)addQuadrangle:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3 point4:(NSPoint)point4 toPath:(NSBezierPath *)path
{
    [path moveToPoint:point1];
    [path lineToPoint:point2];
    [path lineToPoint:point3];
    [path lineToPoint:point4];
    [path lineToPoint:point1];
}

- (void)upateView {
    [self.view clear];
    switch (self.booleanType) {
        case BooleanTypeNone: {
            [self.view addPath:self.path1 withColor:[NSColor blueColor]];
            [self.view addPath:self.path2 withColor:[NSColor redColor]];
        } break;
            
        case BooleanTypeUnion: {
            NSBezierPath *result = [self.path1 fb_union:self.path2];
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeDifference: {
            NSBezierPath *result = [self.path1 fb_difference:self.path2];
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeIntersect: {
            NSBezierPath *result = [self.path1 fb_intersect:self.path2];
            [self.view addPath:result withColor:[NSColor purpleColor]];
        } break;
        case BooleanTypeXOR: {
            NSBezierPath *result = [self.path1 fb_xor:self.path2];
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
