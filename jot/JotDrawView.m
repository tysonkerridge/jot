//
//  JotDrawView.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//

#import "JotDrawView.h"
#import "JotTouchPoint.h"
#import "JotTouchBezier.h"
#import "UIImage+Jot.h"

CGFloat const kJotVelocityFilterWeight = 0.9f;
CGFloat const kJotInitialVelocity = 220.f;
CGFloat const kJotRelativeMinStrokeWidth = 0.4f;

@interface JotDrawView ()

@property (nonatomic, strong) UIImage *cachedImage;

@property (nonatomic, strong) NSMutableArray *pathsArray;

@property (nonatomic, strong) JotTouchBezier *bezierPath;
@property (nonatomic, strong) NSMutableArray *pointsArray;
@property (nonatomic, assign) NSUInteger pointsCounter;
@property (nonatomic, assign) CGFloat lastVelocity;
@property (nonatomic, assign) CGFloat lastWidth;
@property (nonatomic, assign) CGFloat initialVelocity;
@property (nonatomic, assign) BOOL needShowArrow;


@end

@implementation JotDrawView

- (instancetype)init
{
    if ((self = [super init])) {
        
        self.backgroundColor = [UIColor clearColor];
        
        _keepRatio = NO;
        _strokeWidth = 10.f;
        _strokeColor = [UIColor blackColor];
        
        _pathsArray = [NSMutableArray array];
        
        _constantStrokeWidth = NO;
        
        _pointsArray = [NSMutableArray array];
        _initialVelocity = kJotInitialVelocity;
        _lastVelocity = _initialVelocity;
        _lastWidth = _strokeWidth;
        
        self.userInteractionEnabled = NO;
        self.needShowArrow = NO;
    }
    
    return self;
}

#pragma mark - Undo

- (void)clearDrawing
{
    self.cachedImage = nil;
    
    [self.pathsArray removeAllObjects];
    
    self.bezierPath = nil;
    self.pointsCounter = 0;
    [self.pointsArray removeAllObjects];
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
    
    [UIView transitionWithView:self duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self setNeedsDisplay];
                    }
                    completion:nil];
}
- (void)clearLineDrawing
{
    [self.pathsArray removeLastObject];

    self.bezierPath = nil;
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
    
    [UIView transitionWithView:self duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self setNeedsDisplay];
                    }
                    completion:nil];
}
#pragma mark - Properties

- (void)setConstantStrokeWidth:(BOOL)constantStrokeWidth
{
    if (_constantStrokeWidth != constantStrokeWidth) {
        _constantStrokeWidth = constantStrokeWidth;
        self.bezierPath = nil;
        [self.pointsArray removeAllObjects];
        self.pointsCounter = 0;
    }
}

#pragma mark - Draw Touches

- (void)drawTouchBeganAtPoint:(CGPoint)touchPoint
{
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
    self.pointsCounter = 0;
    [self.pointsArray removeAllObjects];
    self.needShowArrow = NO;
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
}

- (void)drawTouchMovedToPoint:(CGPoint)touchPoint
{
    self.pointsCounter += 1;
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
    
    if (self.pointsCounter == 4) {
        
        self.pointsArray[3] = [JotTouchPoint withPoint:CGPointMake(([self.pointsArray[2] CGPointValue].x + [self.pointsArray[4] CGPointValue].x)/2.f,
                                                                   ([self.pointsArray[2] CGPointValue].y + [self.pointsArray[4] CGPointValue].y)/2.f)];
        
        self.bezierPath.startPoint = [self.pointsArray[0] CGPointValue];
        self.bezierPath.endPoint = [self.pointsArray[3] CGPointValue];
        self.bezierPath.controlPoint1 = [self.pointsArray[1] CGPointValue];
        self.bezierPath.controlPoint2 = [self.pointsArray[2] CGPointValue];
        
        if (self.constantStrokeWidth) {
            self.bezierPath.startWidth = self.strokeWidth;
            self.bezierPath.endWidth = self.strokeWidth;
        } else {
            CGFloat velocity = [(JotTouchPoint *)self.pointsArray[3] velocityFromPoint:(JotTouchPoint *)self.pointsArray[0]];
            velocity = (kJotVelocityFilterWeight * velocity) + ((1.f - kJotVelocityFilterWeight) * self.lastVelocity);
            
            CGFloat strokeWidth = [self strokeWidthForVelocity:velocity];
            
            self.bezierPath.startWidth = self.lastWidth;
            self.bezierPath.endWidth = strokeWidth;
            
            self.lastWidth = strokeWidth;
            self.lastVelocity = velocity;
        }
        
        self.pointsArray[0] = self.pointsArray[3];
        self.pointsArray[1] = self.pointsArray[4];
        
        [self drawBitmap];
        
        [self.pointsArray removeLastObject];
        [self.pointsArray removeLastObject];
        [self.pointsArray removeLastObject];
        self.pointsCounter = 1;
    }
}

- (void)drawTouchEnded
{
    [self drawBitmap];
    
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
}

#pragma mark - Draw line Touches

- (void)drawLineBeganAtPoint:(CGPoint)touchPoint
{
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
    self.pointsCounter = 0;
    [self.pointsArray removeAllObjects];
    self.needShowArrow = NO;
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
}

- (void)drawLineMovedToPoint:(CGPoint)touchPoint
{
    [self clearLineDrawing];
    self.bezierPath.startWidth = self.strokeWidth;
    self.bezierPath.endWidth = self.strokeWidth;
    if([self.pointsArray count]>1){
        [self.pointsArray removeLastObject];
    }
    self.pointsCounter++;
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
    
    self.bezierPath.startPoint = [[self.pointsArray firstObject] CGPointValue];
    self.bezierPath.endPoint = [[self.pointsArray lastObject] CGPointValue];
    
    self.bezierPath.controlPoint1 = self.bezierPath.startPoint;
    self.bezierPath.controlPoint2 = self.bezierPath.endPoint;

    //NSLog(@"%lu",(unsigned long)self.pointsCounter);
}

- (void)drawLineEnded
{
    self.pointsCounter = 0;
    [self drawBitmap];
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
}
#pragma mark - Draw line Touches

- (void)drawArrowLineBeganAtPoint:(CGPoint)touchPoint
{   //NSLog(@"drawLineBeganAtPointL: (%f,%f)",touchPoint.x,touchPoint.y);
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
    self.pointsCounter = 0;
    [self.pointsArray removeAllObjects];
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
    self.needShowArrow = YES;
}

- (void)drawArrowLineMovedToPoint:(CGPoint)touchPoint
{
    //NSLog(@"drawLineMovedToPoint: (%f,%f)",touchPoint.x,touchPoint.y);
    [self clearLineDrawing];
    self.bezierPath.startWidth = self.strokeWidth;
    self.bezierPath.endWidth = self.strokeWidth;
    if([self.pointsArray count]>1){
        [self.pointsArray removeLastObject];
    }
    self.pointsCounter++;
    [self.pointsArray addObject:[JotTouchPoint withPoint:touchPoint]];
    
    self.bezierPath.startPoint = [[self.pointsArray firstObject] CGPointValue];
    self.bezierPath.endPoint = [[self.pointsArray lastObject] CGPointValue];
    
    self.bezierPath.controlPoint1 = self.bezierPath.startPoint;
    self.bezierPath.controlPoint2 = self.bezierPath.endPoint;
}

- (void)drawArrowLineEnded
{
    self.pointsCounter = 0;
    [self drawBitmap];
    self.lastVelocity = self.initialVelocity;
    self.lastWidth = self.strokeWidth;
}
#pragma mark - Drawing

- (void)drawBitmap
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    
    if (self.cachedImage) {
        if (self.keepRatio) {
            [self.cachedImage drawInRect:self.bounds];
        } else {
            [self.cachedImage drawAtPoint:CGPointZero];
        }
    }

    [self.bezierPath jotDrawBezier];
    self.bezierPath = nil;
    
    if (self.pointsArray.count == 1) {
        JotTouchPoint *touchPoint = [self.pointsArray firstObject];
        touchPoint.strokeColor = self.strokeColor;
        touchPoint.strokeWidth = 1.5f * [self strokeWidthForVelocity:1.f];
        [self.pathsArray addObject:touchPoint];
        [touchPoint.strokeColor setFill];
        [JotTouchBezier jotDrawBezierPoint:[touchPoint CGPointValue]
                                 withWidth:touchPoint.strokeWidth];
    }
    
    self.cachedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [self.cachedImage drawInRect:rect];

    [self.bezierPath jotDrawBezier];
}

- (CGFloat)strokeWidthForVelocity:(CGFloat)velocity
{
    return self.strokeWidth - ((self.strokeWidth * (1.f - kJotRelativeMinStrokeWidth)) / (1.f + (CGFloat)pow((double)M_E, (double)(-((velocity - self.initialVelocity) / self.initialVelocity)))));
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    _strokeColor = strokeColor;
    self.bezierPath = nil;
}

- (JotTouchBezier *)bezierPath
{
    if (!_bezierPath) {
        _bezierPath = [JotTouchBezier withColor:self.strokeColor];
        [self.pathsArray addObject:_bezierPath];
        _bezierPath.constantWidth = self.constantStrokeWidth;
        if(self.needShowArrow){
            self.bezierPath.needShowArrow = YES;
            self.bezierPath.constantWidth = YES;
        }
        
    }
    
    return _bezierPath;
}

#pragma mark - Image Rendering

- (UIImage *)renderDrawingWithSize:(CGSize)size
{
    return [self drawAllPathsImageWithSize:size
                           backgroundImage:nil];
}

- (UIImage *)drawOnImage:(UIImage *)image
{
    return [self drawAllPathsImageWithSize:image.size backgroundImage:image];
}

- (UIImage *)drawAllPathsImageWithSize:(CGSize)size backgroundImage:(UIImage *)backgroundImage
{
    CGFloat scale = size.width / CGRectGetWidth(self.bounds);
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
    
    [backgroundImage drawInRect:CGRectMake(0.f, 0.f, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    
    [self drawAllPaths];
    
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImage imageWithCGImage:drawnImage.CGImage
                               scale:1.f
                         orientation:drawnImage.imageOrientation];
}

- (void)drawAllPaths
{
    NSArray *tmpPaths = [[NSArray alloc] initWithArray:self.pathsArray];
    @synchronized (self.pathsArray) {
        for (NSObject *path in tmpPaths) {
            if ([path isKindOfClass:[JotTouchBezier class]]) {
                [(JotTouchBezier *)path jotDrawBezier];
            } else if ([path isKindOfClass:[JotTouchPoint class]]) {
                [[(JotTouchPoint *)path strokeColor] setFill];
                [JotTouchBezier jotDrawBezierPoint:[(JotTouchPoint *)path CGPointValue]
                                         withWidth:[(JotTouchPoint *)path strokeWidth]];
            }
        }
    }
}



- (void)drawOnImage:(UIImage *)image block:(void (^)(UIImage *image)) completion
{
    [self drawAllPathsImageWithSize:image.size backgroundImage:image bounds:self.bounds block:completion];
}

- (void)drawAllPathsImageWithSize:(CGSize)size backgroundImage:(UIImage *)backgroundImage bounds:(CGRect)bounds block:(void (^)(UIImage *image)) completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       
                       CGFloat scale = size.width / CGRectGetWidth(bounds);
                       
                       UIGraphicsBeginImageContextWithOptions(bounds.size, NO, scale);
                       
                       [backgroundImage drawInRect:CGRectMake(0.f, 0.f, CGRectGetWidth(bounds), CGRectGetHeight(bounds))];
                       
                       [self drawAllPaths];
                       
                       UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
                       UIGraphicsEndImageContext();
                       UIImage *returnImage = [UIImage imageWithCGImage:drawnImage.CGImage
                                                                  scale:1.f
                                                            orientation:drawnImage.imageOrientation];
                       dispatch_async(dispatch_get_main_queue(), ^(void)
                                      {
                                          completion(returnImage);
                                      });
                       
                   });
    
    
}



@end
