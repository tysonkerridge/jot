//
//  JotTouchBezier.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//

#import "JotTouchBezier.h"
#define ARROW_LENGTH 10.0f
#define ARROW_WIDTH 20.0f;
NSUInteger const kJotDrawStepsPerBezier = 300;

@implementation JotTouchBezier

+ (instancetype)withColor:(UIColor *)color
{
    JotTouchBezier *touchBezier = [JotTouchBezier new];
    
    touchBezier.strokeColor = color;
    
    return touchBezier;
}

- (void)jotDrawBezier
{
    if (self.constantWidth) {
        UIBezierPath *bezierPath = [UIBezierPath new];
        if(self.needShowArrow){
            [bezierPath moveToPoint:self.startPoint];
            [bezierPath addCurveToPoint:self.endPoint controlPoint1:self.controlPoint1 controlPoint2:self.controlPoint2];

            NSArray *arrowPoints = [self getArrowPointsforStart:NO End:YES];
            if(arrowPoints&&[arrowPoints count]>0){
                NSValue *P1 = arrowPoints[0];
                NSValue *P2 = arrowPoints[1];
            
                [bezierPath moveToPoint:self.endPoint];
                [bezierPath addLineToPoint:P1.CGPointValue];
                [bezierPath moveToPoint:self.endPoint];
                [bezierPath addLineToPoint:P2.CGPointValue];
            
            }
        }else{
            [bezierPath moveToPoint:self.startPoint];
            [bezierPath addCurveToPoint:self.endPoint controlPoint1:self.controlPoint1 controlPoint2:self.controlPoint2];
        }
        bezierPath.lineWidth = self.startWidth;
        bezierPath.lineCapStyle = kCGLineCapRound;
        [self.strokeColor setStroke];
        [bezierPath strokeWithBlendMode:kCGBlendModeNormal alpha:1.f];
    } else {
        
            [self.strokeColor setFill];
        
            CGFloat widthDelta = self.endWidth - self.startWidth;
        
            for (NSUInteger i = 0; i < kJotDrawStepsPerBezier; i++) {
            
            CGFloat t = ((CGFloat)i) / (CGFloat)kJotDrawStepsPerBezier;
            CGFloat tt = t * t;
            CGFloat ttt = tt * t;
            CGFloat u = 1.f - t;
            CGFloat uu = u * u;
            CGFloat uuu = uu * u;
            
            CGFloat x = uuu * self.startPoint.x;
            x += 3 * uu * t * self.controlPoint1.x;
            x += 3 * u * tt * self.controlPoint2.x;
            x += ttt * self.endPoint.x;
            
            CGFloat y = uuu * self.startPoint.y;
            y += 3 * uu * t * self.controlPoint1.y;
            y += 3 * u * tt * self.controlPoint2.y;
            y += ttt * self.endPoint.y;
            
            CGFloat pointWidth = self.startWidth + (ttt * widthDelta);
            
            [self.class jotDrawBezierPoint:CGPointMake(x, y) withWidth:pointWidth];
            }
    }
}
//Thanks to this link:  http://stackoverflow.com/questions/2500197/drawing-triangle-arrow-on-a-line-with-cgcontext
- (NSArray *)getArrowPointsforStart: (BOOL) toStart End: (BOOL) toEnd{

    NSArray *arrowPoints;
    
    double slopy, cosy, siny;
    // Arrow size
    double length = ARROW_LENGTH;
    double width = ARROW_WIDTH;
    
    slopy = atan2((self.startPoint.y - self.endPoint.y), (self.startPoint.x - self.endPoint.x));
    cosy = cos(slopy);
    siny = sin(slopy);
    //Caculate the arrow points to help create arrow shape
    if(toStart){
        CGPoint P1 = CGPointMake(self.startPoint.x + ( - length * cosy - ( width / 2.0 * siny )),
                            self.startPoint.y + ( - length * siny + ( width / 2.0 * cosy )));
        CGPoint P2 = CGPointMake(
                            self.startPoint.x + (- length * cosy + ( width / 2.0 * siny )),
                            self.startPoint.y - (width / 2.0 * cosy + length * siny ) );
        arrowPoints = @[[NSValue valueWithCGPoint:P1],
                        [NSValue valueWithCGPoint:P2]];
    }else if(toEnd){
        CGPoint P1 = CGPointMake(self.endPoint.x +  (length * cosy - ( width / 2.0 * siny )),
                                  self.endPoint.y +  (length * siny + ( width / 2.0 * cosy )));
        CGPoint P2 = CGPointMake(self.endPoint.x +  (length * cosy + width / 2.0 * siny),
                             self.endPoint.y -  (width / 2.0 * cosy - length * siny) );
        arrowPoints = @[[NSValue valueWithCGPoint:P1],
                                 [NSValue valueWithCGPoint:P2]];
    }

    return arrowPoints;
}
+ (void)jotDrawBezierPoint:(CGPoint)point withWidth:(CGFloat)width
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    
    CGContextFillEllipseInRect(context, CGRectInset(CGRectMake(point.x, point.y, 0.f, 0.f), -width / 2.f, -width / 2.f));
}

@end
