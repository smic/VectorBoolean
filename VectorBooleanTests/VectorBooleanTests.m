//
//  VectorBooleanTests.m
//  VectorBooleanTests
//
//  Created by Stephan Michels on 18.07.14.
//  Copyright (c) 2014 Fortunate Bear, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VectorBoolean/VectorBoolean.h>

@interface VectorBooleanTests : XCTestCase

@end

@implementation VectorBooleanTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample
//{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
//}

- (void)testSomeOverlap
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(50, 50, 300, 200)];
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(355, 240) withRadius:125];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 350.000000 115.098172 L 350.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 230.394174 250.000000 C 235.488546 314.360016 289.330472 365.000000 355.000000 365.000000 C 424.035594 365.000000 480.000000 309.035594 480.000000 240.000000 C 480.000000 170.964406 424.035594 115.000000 355.000000 115.000000 C 353.325426 115.000000 351.658542 115.032929 349.999961 115.098174 Z M 350.000000 115.098172"];
//    NSLog(@"union(expected):%@", [self stringFromPath:expectedUnionPath]);
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 350.000000 115.098172 L 350.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 230.394174 250.000000 C 230.133049 246.701057 230.000000 243.366066 230.000000 240.000000 C 230.000000 172.638981 283.282313 117.722713 349.999961 115.098174 Z M 350.000000 115.098172"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 350.000000 115.098172 L 350.000000 250.000000 L 230.394174 250.000000 C 230.133049 246.701057 230.000000 243.366066 230.000000 240.000000 C 230.000000 172.638981 283.282313 117.722713 349.999961 115.098174 Z M 350.000000 115.098172"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");

    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 350.000000 115.098172 L 350.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 230.394174 250.000000 C 235.488546 314.360016 289.330472 365.000000 355.000000 365.000000 C 424.035594 365.000000 480.000000 309.035594 480.000000 240.000000 C 480.000000 170.964406 424.035594 115.000000 355.000000 115.000000 C 353.325426 115.000000 351.658542 115.032929 349.999961 115.098174 Z M 350.000000 115.098172 L 350.000000 250.000000 L 230.394174 250.000000 C 230.133049 246.701057 230.000000 243.366066 230.000000 240.000000 C 230.000000 172.638981 283.282313 117.722713 349.999961 115.098174 Z M 350.000000 115.098172"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testCircleInRectangle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(50, 50, 350, 300)];
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:125];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 85.000000 200.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 85.000000 200.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 85.000000 200.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testRectangleInCircle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(150, 150, 150, 150)];
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 15.000000 200.000000 C 15.000000 302.172679 97.827321 385.000000 200.000000 385.000000 C 302.172679 385.000000 385.000000 302.172679 385.000000 200.000000 C 385.000000 97.827321 302.172679 15.000000 200.000000 15.000000 C 97.827321 15.000000 15.000000 97.827321 15.000000 200.000000 Z M 15.000000 200.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@""];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 150.000000 150.000000 L 300.000000 150.000000 L 300.000000 300.000000 L 150.000000 300.000000 L 150.000000 150.000000 Z M 150.000000 150.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 15.000000 200.000000 C 15.000000 302.172679 97.827321 385.000000 200.000000 385.000000 C 302.172679 385.000000 385.000000 302.172679 385.000000 200.000000 C 385.000000 97.827321 302.172679 15.000000 200.000000 15.000000 C 97.827321 15.000000 15.000000 97.827321 15.000000 200.000000 Z M 150.000000 150.000000 L 300.000000 150.000000 L 300.000000 300.000000 L 150.000000 300.000000 L 150.000000 150.000000 Z M 150.000000 150.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testCircleOnRectangle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(15, 15, 370, 370)];
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 15.000000 15.000000 L 385.000000 15.000000 L 385.000000 385.000000 L 15.000000 385.000000 L 15.000000 15.000000 Z M 15.000000 15.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 15.000000 15.000000 L 385.000000 15.000000 L 385.000000 385.000000 L 15.000000 385.000000 L 15.000000 15.000000 Z M 15.000000 200.000000 C 15.000000 302.172679 97.827321 385.000000 200.000000 385.000000 C 302.172679 385.000000 385.000000 302.172679 385.000000 200.000000 C 385.000000 97.827321 302.172679 15.000000 200.000000 15.000000 C 97.827321 15.000000 15.000000 97.827321 15.000000 200.000000 Z M 15.000000 200.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 15.000000 200.000000 C 15.000000 302.172679 97.827321 385.000000 200.000000 385.000000 C 302.172679 385.000000 385.000000 302.172679 385.000000 200.000000 C 385.000000 97.827321 302.172679 15.000000 200.000000 15.000000 C 97.827321 15.000000 15.000000 97.827321 15.000000 200.000000 Z M 15.000000 200.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 15.000000 15.000000 L 385.000000 15.000000 L 385.000000 385.000000 L 15.000000 385.000000 L 15.000000 15.000000 Z M 15.000000 200.000000 C 15.000000 302.172679 97.827321 385.000000 200.000000 385.000000 C 302.172679 385.000000 385.000000 302.172679 385.000000 200.000000 C 385.000000 97.827321 302.172679 15.000000 200.000000 15.000000 C 97.827321 15.000000 15.000000 97.827321 15.000000 200.000000 Z M 15.000000 200.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testHoleyRectangleWithRectangle
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(180, 5, 100, 400) toPath:path2];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 405.000000 L 280.000000 405.000000 L 280.000000 350.000000 L 400.000000 350.000000 L 400.000000 50.000000 L 280.000000 50.000000 L 280.000000 5.000000 L 180.000000 5.000000 L 180.000000 50.000000 Z M 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 321.376768 Z M 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 303.576676 Z M 280.000000 303.576676"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 50.000000 Z M 280.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 280.000000 350.000000 L 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 50.000000 Z M 280.000000 50.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 180.000000 50.000000 L 280.000000 50.000000 L 280.000000 96.423324 C 260.028046 82.899307 235.936514 75.000000 210.000000 75.000000 C 199.658631 75.000000 189.610572 76.255804 180.000000 78.623232 L 180.000000 50.000000 Z M 280.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 189.610572 323.744196 199.658631 325.000000 210.000000 325.000000 C 235.936514 325.000000 260.028046 317.100693 280.000000 303.576676 L 280.000000 350.000000 Z M 280.000000 350.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 405.000000 L 280.000000 405.000000 L 280.000000 350.000000 L 400.000000 350.000000 L 400.000000 50.000000 L 280.000000 50.000000 L 280.000000 5.000000 L 180.000000 5.000000 L 180.000000 50.000000 Z M 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 321.376768 Z M 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 303.576676 Z M 180.000000 50.000000 L 280.000000 50.000000 L 280.000000 96.423324 C 260.028046 82.899307 235.936514 75.000000 210.000000 75.000000 C 199.658631 75.000000 189.610572 76.255804 180.000000 78.623232 L 180.000000 50.000000 Z M 280.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 189.610572 323.744196 199.658631 325.000000 210.000000 325.000000 C 235.936514 325.000000 260.028046 317.100693 280.000000 303.576676 L 280.000000 350.000000 Z M 280.000000 350.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testCircleOnTwoRectangles
{
    NSBezierPath *rectangles = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 5, 100, 400) toPath:rectangles];
    [self addRectangle:NSMakeRect(350, 5, 100, 400) toPath:rectangles];
    NSBezierPath *path1 = rectangles;
    
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 27.979308 122.139823 15.000000 159.554172 15.000000 200.000000 C 15.000000 240.445828 27.979308 277.860177 50.000000 308.305123 L 50.000000 405.000000 L 150.000000 405.000000 L 150.000000 378.164111 C 165.903986 382.618182 182.673841 385.000000 200.000000 385.000000 C 261.726850 385.000000 316.392876 354.769016 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 316.392876 45.230984 261.726850 15.000000 200.000000 15.000000 C 182.673841 15.000000 165.903986 17.381818 150.000000 21.835889 Z M 150.000000 21.835890"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 Z M 150.000000 378.164111 L 150.000000 405.000000 L 50.000000 405.000000 L 50.000000 308.305123 C 74.173914 341.727029 109.243824 366.749934 150.000000 378.164111 Z M 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 378.164111 C 109.243824 366.749934 74.173914 341.727029 50.000000 308.305123 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 Z M 350.000000 308.305123 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 27.979308 122.139823 15.000000 159.554172 15.000000 200.000000 C 15.000000 240.445828 27.979308 277.860177 50.000000 308.305123 L 50.000000 405.000000 L 150.000000 405.000000 L 150.000000 378.164111 C 165.903986 382.618182 182.673841 385.000000 200.000000 385.000000 C 261.726850 385.000000 316.392876 354.769016 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 316.392876 45.230984 261.726850 15.000000 200.000000 15.000000 C 182.673841 15.000000 165.903986 17.381818 150.000000 21.835889 Z M 150.000000 21.835890 L 150.000000 378.164111 C 109.243824 366.749934 74.173914 341.727029 50.000000 308.305123 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 Z M 350.000000 308.305123 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testCircleOverlappingCircle
{
    NSBezierPath *circle = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(355, 240) withRadius:125 toPath:circle];
    NSBezierPath *path1 = circle;
    
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 110) withRadius:100];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 309.068089 123.708933 C 323.286717 118.088324 338.782700 115.000000 355.000000 115.000000 C 424.035594 115.000000 480.000000 170.964406 480.000000 240.000000 C 480.000000 309.035594 424.035594 365.000000 355.000000 365.000000 C 285.964406 365.000000 230.000000 309.035594 230.000000 240.000000 C 230.000000 228.577957 231.531981 217.513728 234.401675 207.001579 C 226.591672 208.960032 218.417285 210.000000 210.000000 210.000000 C 154.771525 210.000000 110.000000 165.228475 110.000000 110.000000 C 110.000000 54.771525 154.771525 10.000000 210.000000 10.000000 C 265.228475 10.000000 310.000000 54.771525 310.000000 110.000000 C 310.000000 114.650622 309.682533 119.227097 309.068089 123.708933 Z M 309.068089 123.708933"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 309.068089 123.708933 C 323.286717 118.088324 338.782700 115.000000 355.000000 115.000000 C 424.035594 115.000000 480.000000 170.964406 480.000000 240.000000 C 480.000000 309.035594 424.035594 365.000000 355.000000 365.000000 C 285.964406 365.000000 230.000000 309.035594 230.000000 240.000000 C 230.000000 228.577957 231.531981 217.513728 234.401675 207.001579 C 273.520525 197.192051 303.497801 164.339362 309.068089 123.708933 Z M 309.068089 123.708933"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 309.068089 123.708933 C 272.773646 138.056091 244.802141 168.903006 234.401675 207.001579 C 273.520525 197.192051 303.497801 164.339362 309.068089 123.708933 Z M 309.068089 123.708933"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 309.068089 123.708933 C 323.286717 118.088324 338.782700 115.000000 355.000000 115.000000 C 424.035594 115.000000 480.000000 170.964406 480.000000 240.000000 C 480.000000 309.035594 424.035594 365.000000 355.000000 365.000000 C 285.964406 365.000000 230.000000 309.035594 230.000000 240.000000 C 230.000000 228.577957 231.531981 217.513728 234.401675 207.001579 C 226.591672 208.960032 218.417285 210.000000 210.000000 210.000000 C 154.771525 210.000000 110.000000 165.228475 110.000000 110.000000 C 110.000000 54.771525 154.771525 10.000000 210.000000 10.000000 C 265.228475 10.000000 310.000000 54.771525 310.000000 110.000000 C 310.000000 114.650622 309.682533 119.227097 309.068089 123.708933 Z M 309.068089 123.708933 C 272.773646 138.056091 244.802141 168.903006 234.401675 207.001579 C 273.520525 197.192051 303.497801 164.339362 309.068089 123.708933 Z M 309.068089 123.708933"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testComplexShapes
{
    NSBezierPath *part1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:part1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:part1];
    
    NSBezierPath *part2 = [self pathWithRectangle:NSMakeRect(180, 5, 100, 400)];
    
    NSBezierPath *allParts = [part1 fb_union:part2];
    NSBezierPath *intersectingParts = [part1 fb_intersect:part2];
    
    NSBezierPath *path1 = allParts;
    NSBezierPath *path2 = intersectingParts;
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 405.000000 L 280.000000 405.000000 L 280.000000 350.000000 L 400.000000 350.000000 L 400.000000 50.000000 L 280.000000 50.000000 L 280.000000 5.000000 L 180.000000 5.000000 L 180.000000 50.000000 L 180.000000 50.000000 Z M 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 321.376768 L 180.000000 321.376768 Z M 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 303.576676 L 280.000000 303.576676 Z M 280.000000 303.576676"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 405.000000 L 280.000000 405.000000 L 280.000000 350.000000 L 400.000000 350.000000 L 400.000000 50.000000 L 280.000000 50.000000 L 280.000000 5.000000 L 180.000000 5.000000 L 180.000000 50.000000 L 180.000000 50.000000 Z M 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 321.376768 L 180.000000 321.376768 Z M 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 303.576676 L 280.000000 303.576676 Z M 180.000000 50.000000 L 280.000000 50.000000 L 280.000000 96.423324 C 260.028046 82.899307 235.936514 75.000000 210.000000 75.000000 C 199.658631 75.000000 189.610572 76.255804 180.000000 78.623232 L 180.000000 50.000000 L 180.000000 50.000000 Z M 280.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 189.610572 323.744196 199.658631 325.000000 210.000000 325.000000 C 235.936514 325.000000 260.028046 317.100693 280.000000 303.576676 L 280.000000 350.000000 L 280.000000 350.000000 Z M 280.000000 350.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 180.000000 50.000000 L 280.000000 50.000000 L 280.000000 96.423324 C 260.028046 82.899307 235.936514 75.000000 210.000000 75.000000 C 199.658631 75.000000 189.610572 76.255804 180.000000 78.623232 L 180.000000 50.000000 L 180.000000 50.000000 Z M 280.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 189.610572 323.744196 199.658631 325.000000 210.000000 325.000000 C 235.936514 325.000000 260.028046 317.100693 280.000000 303.576676 L 280.000000 350.000000 L 280.000000 350.000000 Z M 280.000000 350.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 180.000000 50.000000 L 50.000000 50.000000 L 50.000000 350.000000 L 180.000000 350.000000 L 180.000000 405.000000 L 280.000000 405.000000 L 280.000000 350.000000 L 400.000000 350.000000 L 400.000000 50.000000 L 280.000000 50.000000 L 280.000000 5.000000 L 180.000000 5.000000 L 180.000000 50.000000 L 180.000000 50.000000 Z M 180.000000 321.376768 C 125.453539 307.940020 85.000000 258.694225 85.000000 200.000000 C 85.000000 141.305775 125.453539 92.059980 180.000000 78.623232 L 180.000000 321.376768 L 180.000000 321.376768 Z M 280.000000 303.576676 C 313.187685 281.103620 335.000000 243.099080 335.000000 200.000000 C 335.000000 156.900920 313.187685 118.896380 280.000000 96.423324 L 280.000000 303.576676 L 280.000000 303.576676 Z M 180.000000 50.000000 L 280.000000 50.000000 L 280.000000 96.423324 C 260.028046 82.899307 235.936514 75.000000 210.000000 75.000000 C 199.658631 75.000000 189.610572 76.255804 180.000000 78.623232 L 180.000000 50.000000 L 180.000000 50.000000 Z M 280.000000 350.000000 L 180.000000 350.000000 L 180.000000 321.376768 C 189.610572 323.744196 199.658631 325.000000 210.000000 325.000000 C 235.936514 325.000000 260.028046 317.100693 280.000000 303.576676 L 280.000000 350.000000 L 280.000000 350.000000 Z M 280.000000 350.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testComplexShapes2
{
    NSBezierPath *part1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 5, 100, 400) toPath:part1];
    [self addRectangle:NSMakeRect(350, 5, 100, 400) toPath:part1];
    
    NSBezierPath *part2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 200) withRadius:185 toPath:part2];
    
    NSBezierPath *allParts = [part1 fb_union:part2];
    NSBezierPath *intersectingParts = [part1 fb_intersect:part2];
    
    NSBezierPath *path1 = allParts;
    NSBezierPath *path2 = intersectingParts;
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 27.979308 122.139823 15.000000 159.554172 15.000000 200.000000 C 15.000000 240.445828 27.979308 277.860177 50.000000 308.305123 L 50.000000 405.000000 L 150.000000 405.000000 L 150.000000 378.164111 C 165.903986 382.618182 182.673841 385.000000 200.000000 385.000000 C 261.726850 385.000000 316.392876 354.769016 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 316.392876 45.230984 261.726850 15.000000 200.000000 15.000000 C 182.673841 15.000000 165.903986 17.381818 150.000000 21.835889 L 150.000000 21.835890 Z M 150.000000 21.835890"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 27.979308 122.139823 15.000000 159.554172 15.000000 200.000000 C 15.000000 240.445828 27.979308 277.860177 50.000000 308.305123 L 50.000000 405.000000 L 150.000000 405.000000 L 150.000000 378.164111 C 165.903986 382.618182 182.673841 385.000000 200.000000 385.000000 C 261.726850 385.000000 316.392876 354.769016 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 316.392876 45.230984 261.726850 15.000000 200.000000 15.000000 C 182.673841 15.000000 165.903986 17.381818 150.000000 21.835889 L 150.000000 21.835890 Z M 150.000000 21.835890 L 150.000000 378.164111 C 109.243824 366.749934 74.173914 341.727029 50.000000 308.305123 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 L 150.000000 21.835890 Z M 350.000000 308.305123 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 L 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 378.164111 C 109.243824 366.749934 74.173914 341.727029 50.000000 308.305123 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 L 150.000000 21.835890 Z M 350.000000 308.305123 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 L 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 150.000000 21.835890 L 150.000000 5.000000 L 50.000000 5.000000 L 50.000000 91.694877 C 27.979308 122.139823 15.000000 159.554172 15.000000 200.000000 C 15.000000 240.445828 27.979308 277.860177 50.000000 308.305123 L 50.000000 405.000000 L 150.000000 405.000000 L 150.000000 378.164111 C 165.903986 382.618182 182.673841 385.000000 200.000000 385.000000 C 261.726850 385.000000 316.392876 354.769016 350.000000 308.305123 L 350.000000 405.000000 L 450.000000 405.000000 L 450.000000 5.000000 L 350.000000 5.000000 L 350.000000 91.694877 C 316.392876 45.230984 261.726850 15.000000 200.000000 15.000000 C 182.673841 15.000000 165.903986 17.381818 150.000000 21.835889 L 150.000000 21.835890 Z M 150.000000 21.835890 L 150.000000 378.164111 C 109.243824 366.749934 74.173914 341.727029 50.000000 308.305123 L 50.000000 91.694877 C 74.173914 58.272971 109.243824 33.250066 150.000000 21.835889 L 150.000000 21.835890 Z M 350.000000 308.305123 L 350.000000 91.694877 C 372.020692 122.139823 385.000000 159.554172 385.000000 200.000000 C 385.000000 240.445828 372.020692 277.860177 350.000000 308.305123 L 350.000000 308.305123 Z M 350.000000 308.305123"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testTriangleInsideRectangle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(100, 100, 300, 300)];
    NSBezierPath *path2 = [self pathWithTriangle:NSMakePoint(100, 400) point2:NSMakePoint(400, 400) point3:NSMakePoint(250, 250)];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 100.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 400.000000 L 400.000000 400.000000 L 250.000000 250.000000 L 100.000000 400.000000 Z M 100.000000 400.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 100.000000 400.000000 L 400.000000 400.000000 L 250.000000 250.000000 L 100.000000 400.000000 Z M 100.000000 400.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 400.000000 L 400.000000 400.000000 L 250.000000 250.000000 L 100.000000 400.000000 Z M 100.000000 400.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testDiamondOverlappingRectangle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(50, 50, 200, 200)];
    NSBezierPath *path2 = [self pathWithQuadrangle:NSMakePoint(50, 250) point2:NSMakePoint(150, 400) point3:NSMakePoint(250, 250) point4:NSMakePoint(150, 100)];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 250.000000 250.000000 L 250.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 150.000000 400.000000 L 250.000000 250.000000 Z M 250.000000 250.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 250.000000 250.000000 L 250.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 150.000000 100.000000 L 250.000000 250.000000 Z M 250.000000 250.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 250.000000 250.000000 L 50.000000 250.000000 L 150.000000 100.000000 L 250.000000 250.000000 Z M 250.000000 250.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 250.000000 250.000000 L 250.000000 50.000000 L 50.000000 50.000000 L 50.000000 250.000000 L 150.000000 400.000000 L 250.000000 250.000000 Z M 250.000000 250.000000 L 50.000000 250.000000 L 150.000000 100.000000 L 250.000000 250.000000 Z M 250.000000 250.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testDiamondInsideRectangle
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(100, 100, 300, 300)];
    NSBezierPath *path2 = [self pathWithQuadrangle:NSMakePoint(100, 250) point2:NSMakePoint(250, 400) point3:NSMakePoint(400, 250) point4:NSMakePoint(250, 100)];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 100.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 250.000000 L 250.000000 400.000000 L 400.000000 250.000000 L 250.000000 100.000000 L 100.000000 250.000000 Z M 100.000000 250.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 100.000000 250.000000 L 250.000000 400.000000 L 400.000000 250.000000 L 250.000000 100.000000 L 100.000000 250.000000 Z M 100.000000 250.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 100.000000 100.000000 L 400.000000 100.000000 L 400.000000 400.000000 L 100.000000 400.000000 L 100.000000 100.000000 Z M 100.000000 250.000000 L 250.000000 400.000000 L 400.000000 250.000000 L 250.000000 100.000000 L 100.000000 250.000000 Z M 100.000000 250.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testNonOverlappingContours
{
    NSBezierPath *path1 = [self pathWithRectangle:NSMakeRect(100, 200, 200, 200)];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:NSMakePoint(200, 95) withRadius:85 toPath:path2];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 95.000000 C 115.000000 141.944204 153.055796 180.000000 200.000000 180.000000 C 246.944204 180.000000 285.000000 141.944204 285.000000 95.000000 C 285.000000 48.055796 246.944204 10.000000 200.000000 10.000000 C 153.055796 10.000000 115.000000 48.055796 115.000000 95.000000 Z M 115.000000 95.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 95.000000 C 115.000000 141.944204 153.055796 180.000000 200.000000 180.000000 C 246.944204 180.000000 285.000000 141.944204 285.000000 95.000000 C 285.000000 48.055796 246.944204 10.000000 200.000000 10.000000 C 153.055796 10.000000 115.000000 48.055796 115.000000 95.000000 Z M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testMoreNonOverlappingContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(100, 200, 200, 200) toPath:path1];
    [self addRectangle:NSMakeRect(175, 70, 50, 50) toPath:path1];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(200, 300) withRadius:85 toPath:path2];
    [self addCircleAtPoint:NSMakePoint(200, 95) withRadius:85 toPath:path2];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 95.000000 C 115.000000 141.944204 153.055796 180.000000 200.000000 180.000000 C 246.944204 180.000000 285.000000 141.944204 285.000000 95.000000 C 285.000000 48.055796 246.944204 10.000000 200.000000 10.000000 C 153.055796 10.000000 115.000000 48.055796 115.000000 95.000000 Z M 115.000000 95.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 175.000000 70.000000 L 225.000000 70.000000 L 225.000000 120.000000 L 175.000000 120.000000 L 175.000000 70.000000 Z M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 100.000000 200.000000 L 300.000000 200.000000 L 300.000000 400.000000 L 100.000000 400.000000 L 100.000000 200.000000 Z M 115.000000 95.000000 C 115.000000 141.944204 153.055796 180.000000 200.000000 180.000000 C 246.944204 180.000000 285.000000 141.944204 285.000000 95.000000 C 285.000000 48.055796 246.944204 10.000000 200.000000 10.000000 C 153.055796 10.000000 115.000000 48.055796 115.000000 95.000000 Z M 175.000000 70.000000 L 225.000000 70.000000 L 225.000000 120.000000 L 175.000000 120.000000 L 175.000000 70.000000 Z M 115.000000 300.000000 C 115.000000 346.944204 153.055796 385.000000 200.000000 385.000000 C 246.944204 385.000000 285.000000 346.944204 285.000000 300.000000 C 285.000000 253.055796 246.944204 215.000000 200.000000 215.000000 C 153.055796 215.000000 115.000000 253.055796 115.000000 300.000000 Z M 115.000000 300.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testConcentricContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:140];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 70.000000 200.000000 C 70.000000 277.319865 132.680135 340.000000 210.000000 340.000000 C 287.319865 340.000000 350.000000 277.319865 350.000000 200.000000 C 350.000000 122.680135 287.319865 60.000000 210.000000 60.000000 C 132.680135 60.000000 70.000000 122.680135 70.000000 200.000000 Z M 70.000000 200.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 70.000000 200.000000 C 70.000000 277.319865 132.680135 340.000000 210.000000 340.000000 C 287.319865 340.000000 350.000000 277.319865 350.000000 200.000000 C 350.000000 122.680135 287.319865 60.000000 210.000000 60.000000 C 132.680135 60.000000 70.000000 122.680135 70.000000 200.000000 Z M 70.000000 200.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 70.000000 200.000000 C 70.000000 277.319865 132.680135 340.000000 210.000000 340.000000 C 287.319865 340.000000 350.000000 277.319865 350.000000 200.000000 C 350.000000 122.680135 287.319865 60.000000 210.000000 60.000000 C 132.680135 60.000000 70.000000 122.680135 70.000000 200.000000 Z M 70.000000 200.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testMoreConcentricContours
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    
    NSBezierPath *path2 = [self pathWithCircleAtPoint:NSMakePoint(210, 200) withRadius:70];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 140.000000 200.000000 C 140.000000 238.659932 171.340068 270.000000 210.000000 270.000000 C 248.659932 270.000000 280.000000 238.659932 280.000000 200.000000 C 280.000000 161.340068 248.659932 130.000000 210.000000 130.000000 C 171.340068 130.000000 140.000000 161.340068 140.000000 200.000000 Z M 140.000000 200.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 85.000000 200.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@""];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 85.000000 200.000000 C 85.000000 269.035594 140.964406 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 130.964406 279.035594 75.000000 210.000000 75.000000 C 140.964406 75.000000 85.000000 130.964406 85.000000 200.000000 Z M 140.000000 200.000000 C 140.000000 238.659932 171.340068 270.000000 210.000000 270.000000 C 248.659932 270.000000 280.000000 238.659932 280.000000 200.000000 C 280.000000 161.340068 248.659932 130.000000 210.000000 130.000000 C 171.340068 130.000000 140.000000 161.340068 140.000000 200.000000 Z M 140.000000 200.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testOverlappingHole
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addCircleAtPoint:NSMakePoint(180, 180) withRadius:125 toPath:path2];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 126.460177 292.985881 C 148.599580 312.889325 177.885490 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 150.123348 305.788063 107.069509 263.539823 87.014119 C 288.992826 109.896508 305.000000 143.078916 305.000000 180.000000 C 305.000000 249.035594 249.035594 305.000000 180.000000 305.000000 C 160.841058 305.000000 142.688844 300.689687 126.460177 292.985881 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 126.460177 292.985881 C 148.599580 312.889325 177.885490 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 150.123348 305.788063 107.069509 263.539823 87.014119 C 241.400420 67.110675 212.114510 55.000000 180.000000 55.000000 C 110.964406 55.000000 55.000000 110.964406 55.000000 180.000000 C 55.000000 229.876652 84.211937 272.930491 126.460177 292.985881 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 126.460177 292.985881 C 101.007174 270.103492 85.000000 236.921084 85.000000 200.000000 C 85.000000 130.964406 140.964406 75.000000 210.000000 75.000000 C 229.158942 75.000000 247.311156 79.310313 263.539823 87.014119 C 241.400420 67.110675 212.114510 55.000000 180.000000 55.000000 C 110.964406 55.000000 55.000000 110.964406 55.000000 180.000000 C 55.000000 229.876652 84.211937 272.930491 126.460177 292.985881 Z M 126.460177 292.985881"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 126.460177 292.985881 C 148.599580 312.889325 177.885490 325.000000 210.000000 325.000000 C 279.035594 325.000000 335.000000 269.035594 335.000000 200.000000 C 335.000000 150.123348 305.788063 107.069509 263.539823 87.014119 C 288.992826 109.896508 305.000000 143.078916 305.000000 180.000000 C 305.000000 249.035594 249.035594 305.000000 180.000000 305.000000 C 160.841058 305.000000 142.688844 300.689687 126.460177 292.985881 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 126.460177 292.985881 C 101.007174 270.103492 85.000000 236.921084 85.000000 200.000000 C 85.000000 130.964406 140.964406 75.000000 210.000000 75.000000 C 229.158942 75.000000 247.311156 79.310313 263.539823 87.014119 C 241.400420 67.110675 212.114510 55.000000 180.000000 55.000000 C 110.964406 55.000000 55.000000 110.964406 55.000000 180.000000 C 55.000000 229.876652 84.211937 272.930491 126.460177 292.985881 Z M 126.460177 292.985881"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testHoleOverlappingHole
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:path1];
    [self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:path1];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [self addRectangle:NSMakeRect(225, 65, 160, 160) toPath:path2];
    [self addCircleAtPoint:NSMakePoint(305, 145) withRadius:65 toPath:path2];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
//    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 332.499547 225.000000 C 320.917789 282.056008 270.473948 325.000000 210.000000 325.000000 C 140.964406 325.000000 85.000000 269.035594 85.000000 200.000000 C 85.000000 130.964406 140.964406 75.000000 210.000000 75.000000 C 215.076361 75.000000 220.082046 75.302601 225.000000 75.890750 L 225.000000 225.000000 L 332.499547 225.000000 Z M 334.971572 202.692701 C 334.990492 201.797418 335.000000 200.899819 335.000000 200.000000 C 335.000000 152.674739 308.700238 111.492116 269.918821 90.270237 C 251.922573 101.829559 240.000000 122.022447 240.000000 145.000000 C 240.000000 180.898509 269.101491 210.000000 305.000000 210.000000 C 315.809843 210.000000 326.003369 207.361232 334.971572 202.692701 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
//    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 332.499547 225.000000 C 320.917789 282.056008 270.473948 325.000000 210.000000 325.000000 C 140.964406 325.000000 85.000000 269.035594 85.000000 200.000000 C 85.000000 130.964406 140.964406 75.000000 210.000000 75.000000 C 215.076361 75.000000 220.082046 75.302601 225.000000 75.890750 L 225.000000 65.000000 L 385.000000 65.000000 L 385.000000 225.000000 L 332.499547 225.000000 Z M 334.971572 202.692701 C 334.990492 201.797418 335.000000 200.899819 335.000000 200.000000 C 335.000000 152.674739 308.700238 111.492116 269.918821 90.270237 C 280.038641 83.770090 292.079045 80.000000 305.000000 80.000000 C 340.898509 80.000000 370.000000 109.101491 370.000000 145.000000 C 370.000000 170.088666 355.785959 191.857465 334.971572 202.692701 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 50.000000 50.000000"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
//    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 332.499547 225.000000 C 333.966913 217.771214 334.810467 210.315902 334.971572 202.692701 C 355.785959 191.857465 370.000000 170.088666 370.000000 145.000000 C 370.000000 109.101491 340.898509 80.000000 305.000000 80.000000 C 292.079045 80.000000 280.038641 83.770090 269.918821 90.270237 C 256.287855 82.811131 241.114912 77.817966 225.000000 75.890750 L 225.000000 65.000000 L 385.000000 65.000000 L 385.000000 225.000000 L 332.499547 225.000000 Z M 332.499547 225.000000"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
//    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 332.499547 225.000000 C 320.917789 282.056008 270.473948 325.000000 210.000000 325.000000 C 140.964406 325.000000 85.000000 269.035594 85.000000 200.000000 C 85.000000 130.964406 140.964406 75.000000 210.000000 75.000000 C 215.076361 75.000000 220.082046 75.302601 225.000000 75.890750 L 225.000000 225.000000 L 332.499547 225.000000 Z M 334.971572 202.692701 C 334.990492 201.797418 335.000000 200.899819 335.000000 200.000000 C 335.000000 152.674739 308.700238 111.492116 269.918821 90.270237 C 251.922573 101.829559 240.000000 122.022447 240.000000 145.000000 C 240.000000 180.898509 269.101491 210.000000 305.000000 210.000000 C 315.809843 210.000000 326.003369 207.361232 334.971572 202.692701 Z M 50.000000 50.000000 L 400.000000 50.000000 L 400.000000 350.000000 L 50.000000 350.000000 L 50.000000 50.000000 Z M 332.499547 225.000000 C 333.966913 217.771214 334.810467 210.315902 334.971572 202.692701 C 355.785959 191.857465 370.000000 170.088666 370.000000 145.000000 C 370.000000 109.101491 340.898509 80.000000 305.000000 80.000000 C 292.079045 80.000000 280.038641 83.770090 269.918821 90.270237 C 256.287855 82.811131 241.114912 77.817966 225.000000 75.890750 L 225.000000 65.000000 L 385.000000 65.000000 L 385.000000 225.000000 L 332.499547 225.000000 Z M 332.499547 225.000000"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
}

- (void)testCurvyShapeOverlappingRectangle
{
    NSBezierPath *path1 = [NSBezierPath bezierPath];
    CGFloat top = 65.0 + 160.0 / 3.0;
    [path1 moveToPoint:NSMakePoint(40, top)];
    [path1 lineToPoint:NSMakePoint(410, top)];
    [path1 lineToPoint:NSMakePoint(410, 50)];
    [path1 lineToPoint:NSMakePoint(40, 50)];
    [path1 lineToPoint:NSMakePoint(40, top)];
    
    NSBezierPath *path2 = [NSBezierPath bezierPath];
    [path2 moveToPoint:NSMakePoint(335.000000, 203.000000)];
    [path2 curveToPoint:NSMakePoint(335.000000, 200.000000) controlPoint1:NSMakePoint(335.000000, 202.000000) controlPoint2:NSMakePoint(335.000000, 201.000000)];
    [path2 curveToPoint:NSMakePoint(270.000000, 90.000000) controlPoint1:NSMakePoint(335.000000, 153.000000) controlPoint2:NSMakePoint(309.000000, 111.000000)];
    [path2 curveToPoint:NSMakePoint(240.000000, 145.000000) controlPoint1:NSMakePoint(252.000000, 102.000000) controlPoint2:NSMakePoint(240.000000, 122.000000)];
    [path2 curveToPoint:NSMakePoint(305.000000, 210.000000) controlPoint1:NSMakePoint(240.000000, 181.000000) controlPoint2:NSMakePoint(269.000000, 210.000000)];
    [path2 curveToPoint:NSMakePoint(335.000000, 203.000000) controlPoint1:NSMakePoint(316.000000, 210.000000) controlPoint2:NSMakePoint(326.000000, 207.000000)];
    
    NSBezierPath *unionPath = [path1 fb_union:path2];
    NSLog(@"union:%@", [self stringFromPath:unionPath]);
    NSBezierPath *expectedUnionPath = [self pathFromString:@"M 245.743611 118.333333 L 40.000000 118.333333 L 40.000000 50.000000 L 410.000000 50.000000 L 410.000000 118.333333 L 304.982393 118.333333 C 323.762887 140.363817 335.000000 169.101417 335.000000 200.000000 C 335.000000 201.000000 335.000000 202.000000 335.000000 203.000000 C 326.000000 207.000000 316.000000 210.000000 305.000000 210.000000 C 269.000000 210.000000 240.000000 181.000000 240.000000 145.000000 C 240.000000 135.478772 242.056419 126.471649 245.743611 118.333333 Z M 245.743611 118.333333"];
    XCTAssertTrue([self equalsPath:unionPath toPath:expectedUnionPath], @"Union path not equal");
    
    NSBezierPath *differencePath = [path1 fb_difference:path2];
    NSLog(@"difference:%@", [self stringFromPath:differencePath]);
    NSBezierPath *expectedDifferencePath = [self pathFromString:@"M 245.743611 118.333333 L 40.000000 118.333333 L 40.000000 50.000000 L 410.000000 50.000000 L 410.000000 118.333333 L 304.982393 118.333333 C 295.195777 106.853130 283.360750 97.194250 270.000000 90.000000 C 259.451396 97.032403 250.963404 106.812288 245.743611 118.333333 Z M 245.743611 118.333333"];
    XCTAssertTrue([self equalsPath:differencePath toPath:expectedDifferencePath], @"Difference path not equal");
    
    NSBezierPath *intersectPath = [path1 fb_intersect:path2];
    NSLog(@"intersect:%@", [self stringFromPath:intersectPath]);
    NSBezierPath *expectedIntersectPath = [self pathFromString:@"M 245.743611 118.333333 L 304.982393 118.333333 C 295.195777 106.853130 283.360750 97.194250 270.000000 90.000000 C 259.451396 97.032403 250.963404 106.812288 245.743611 118.333333 Z M 245.743611 118.333333"];
    XCTAssertTrue([self equalsPath:intersectPath toPath:expectedIntersectPath], @"Intersect path not equal");
    
    NSBezierPath *xorPath = [path1 fb_xor:path2];
    NSLog(@"xor:%@", [self stringFromPath:xorPath]);
    NSBezierPath *expectedXORPath = [self pathFromString:@"M 245.743611 118.333333 L 40.000000 118.333333 L 40.000000 50.000000 L 410.000000 50.000000 L 410.000000 118.333333 L 304.982393 118.333333 C 323.762887 140.363817 335.000000 169.101417 335.000000 200.000000 C 335.000000 201.000000 335.000000 202.000000 335.000000 203.000000 C 326.000000 207.000000 316.000000 210.000000 305.000000 210.000000 C 269.000000 210.000000 240.000000 181.000000 240.000000 145.000000 C 240.000000 135.478772 242.056419 126.471649 245.743611 118.333333 Z M 245.743611 118.333333 L 304.982393 118.333333 C 295.195777 106.853130 283.360750 97.194250 270.000000 90.000000 C 259.451396 97.032403 250.963404 106.812288 245.743611 118.333333 Z M 245.743611 118.333333"];
    XCTAssertTrue([self equalsPath:xorPath toPath:expectedXORPath], @"XOR path not equal");
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

- (NSString *)stringFromPath:(NSBezierPath *)path {
    NSMutableString *string = [NSMutableString string];
    
    NSInteger numElements = [path elementCount];
    NSPoint points[3];
    
    for (NSUInteger i = 0; i < numElements; i++) {
        if (string.length > 0) {
            [string appendString:@" "];
        }
        switch ([path elementAtIndex:i associatedPoints:points]) {
            case NSMoveToBezierPathElement:
                [string appendFormat:@"M %f %f", points[0].x, points[0].y];
                break;
                
            case NSLineToBezierPathElement:
                [string appendFormat:@"L %f %f", points[0].x, points[0].y];
                break;
                
            case NSCurveToBezierPathElement:
                 [string appendFormat:@"C %f %f %f %f %f %f", points[0].x, points[0].y,
                  points[1].x, points[1].y,
                  points[2].x, points[2].y];
                break;
                
            case NSClosePathBezierPathElement:
                [string appendString:@"Z"];
                break;
                
            default:
                break;
        }
    }

    return string;
}

- (NSBezierPath *)pathFromString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint points[3];
    while (![scanner isAtEnd]) {
        if ([scanner scanString:@"M" intoString:NULL]) {
            if (![scanner scanDouble:&(points[0].x)]) {
                break;
            }
            if (![scanner scanDouble:&(points[0].y)]) {
                break;
            }
            [path moveToPoint:points[0]];
            continue;
        }
        if ([scanner scanString:@"L" intoString:NULL]) {
            if (![scanner scanDouble:&(points[0].x)]) {
                break;
            }
            if (![scanner scanDouble:&(points[0].y)]) {
                break;
            }
            [path lineToPoint:points[0]];
            continue;
        }
        if ([scanner scanString:@"C" intoString:NULL]) {
            if (![scanner scanDouble:&(points[0].x)]) {
                break;
            }
            if (![scanner scanDouble:&(points[0].y)]) {
                break;
            }
            if (![scanner scanDouble:&(points[1].x)]) {
                break;
            }
            if (![scanner scanDouble:&(points[1].y)]) {
                break;
            }
            if (![scanner scanDouble:&(points[2].x)]) {
                break;
            }
            if (![scanner scanDouble:&(points[2].y)]) {
                break;
            }
            [path curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]];
            continue;
        }
        if ([scanner scanString:@"Z" intoString:NULL]) {
            [path closePath];
            continue;
        }
        break;
    }
    return path;
}

- (BOOL)equalsPath:(NSBezierPath *)path1 toPath:(NSBezierPath *)path2 {
    NSInteger numElements = path1.elementCount;
    if (path2.elementCount != numElements) {
        return NO;
    }
    NSPoint points1[3];
    NSPoint points2[3];
    
    CGFloat epsilon = 0.001;
    for (NSUInteger i = 0; i < numElements; i++) {
        NSBezierPathElement element = [path1 elementAtIndex:i associatedPoints:points1];
        if (element != [path2 elementAtIndex:i associatedPoints:points2]) {
            return NO;
        }
        switch (element) {
            case NSMoveToBezierPathElement:
                if (ABS(points1[0].x - points2[0].x) > epsilon ||
                    ABS(points1[0].y - points2[0].y) > epsilon) {
                    return NO;
                }
                break;
                
            case NSLineToBezierPathElement:
                if (ABS(points1[0].x - points2[0].x) > epsilon ||
                    ABS(points1[0].y - points2[0].y) > epsilon) {
                    return NO;
                }
                break;
                
            case NSCurveToBezierPathElement:
                if (ABS(points1[0].x - points2[0].x) > epsilon ||
                    ABS(points1[0].y - points2[0].y) > epsilon ||
                    ABS(points1[1].x - points2[1].x) > epsilon ||
                    ABS(points1[1].y - points2[1].y) > epsilon ||
                    ABS(points1[2].x - points2[2].x) > epsilon ||
                    ABS(points1[2].y - points2[2].y) > epsilon) {
                    return NO;
                }
                break;
                
            case NSClosePathBezierPathElement:
                // nothing
                break;
                
            default:
                break;
        }
    }
    return YES;
}

@end
