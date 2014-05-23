//
//  SQFullscreenAlert.m
//  Scratch3
//
//  Created by Nate Parrott on 5/19/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQFullscreenAlert.h"

@interface SQFullscreenAlert ()

@property(strong)UIImageView* imageView;
@property(strong)NSArray* backgroundViews;
@property(strong)CALayer* clipLayer;

@end


@implementation SQFullscreenAlert

/*-(CATransform3D)skewTransform:(CGFloat)skew {
    return CATransform3DMakeAffineTransform(CGAffineTransformMake(1.f, 0.f, skew, 1.f, 0.f, 0.f));
}*/
-(id)init {
    self = [super initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self setup];
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}
-(void)setup {
    self.imageView = [UIImageView new];
    [self addSubview:self.imageView];
    
    self.backgroundViews = @[[UIView new], [UIView new], [UIView new], [UIView new]];
    for (UIView* view in self.backgroundViews) {
        [self addSubview:view];
    }
    
    self.clipLayer = [CALayer layer];
    self.clipLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.layer.mask = self.clipLayer;
    self.hidden = YES;
}

-(void)setImage:(UIImage*)image text:(NSString*)text {
    UIGraphicsBeginImageContextWithOptions(self.contentSize, NO, 0);
    
    NSDictionary* textAttributes = @{NSFontAttributeName: self.font};
    CGSize textSize = [text sizeWithAttributes:textAttributes];
    [text drawInRect:CGRectMake((self.contentSize.width-textSize.width)/2, self.contentSize.height-textSize.height, textSize.width, textSize.height) withAttributes:textAttributes];
    
    CGFloat availableHeight = self.contentSize.height - textSize.height*1.35;
    CGFloat imageScale = MIN(1, MIN(self.contentSize.width/image.size.width, availableHeight/image.size.height));
    CGSize imageSize = CGSizeMake(image.size.width*imageScale, image.size.height*imageScale);
    CGPoint imageCenter = CGPointMake(self.contentSize.width/2, availableHeight/2);
    [image drawInRect:CGRectMake(imageCenter.x-imageSize.width/2, imageCenter.y-imageSize.height/2, imageSize.width, imageSize.height)];
    
    CGImageRef mask = UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(self.contentSize, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, self.contentSize.height);
    CGContextScaleCTM(ctx, 1, -1);
    
    [self.blackoutColor setFill];
    CGRect full = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    CGContextFillRect(ctx, full);
    
    CGContextClipToMask(ctx, full, mask);
    
    CGContextClearRect(ctx, full);
    [self.contentColor setFill];
    CGContextFillRect(ctx, full);
    
    UIImage* processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    for (UIView* view in self.backgroundViews) view.backgroundColor = self.blackoutColor;
    
    self.imageView.image = processedImage;
    
    [self setNeedsLayout];
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.imageView.bounds = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    CGFloat topY = self.imageView.frame.origin.y;
    CGFloat bottomY = topY + self.imageView.frame.size.height;
    CGFloat minX = self.imageView.frame.origin.x;
    CGFloat maxX = minX + self.imageView.frame.size.width;
    [self.backgroundViews[0] setFrame:CGRectMake(0, 0, self.bounds.size.width, topY)];
    [self.backgroundViews[1] setFrame:CGRectMake(0, bottomY, self.bounds.size.width, self.bounds.size.height-bottomY)];
    [self.backgroundViews[2] setFrame:CGRectMake(0, topY, minX, bottomY-topY)];
    [self.backgroundViews[3] setFrame:CGRectMake(maxX, topY, self.bounds.size.width-maxX, bottomY-topY)];
    
    CGFloat clipWidth = sqrtf(powf(self.bounds.size.width, 2) + powf(self.bounds.size.height, 2));
    self.clipLayer.bounds = CGRectMake(0, 0, clipWidth, clipWidth);
    self.clipLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.clipLayer.cornerRadius = clipWidth/2;
}
-(void)presentQuick:(BOOL)quickIn andDismissAfter:(NSTimeInterval)displayDuration {
    [self presentWithDuration:quickIn? 0.1 : 0.6 callback:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(displayDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissWithDuration:0.6 callback:^{
                
            }];
        });
    }];
}
-(void)dismissQuietly {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.alpha = 1;
        self.hidden = YES;
    }];
}
-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    [self dismissQuietly];
    return nil;
}
-(void)presentWithDuration:(NSTimeInterval)duration callback:(void(^)())done {
    self.hidden = NO;
    [self setClipScaleFrom:0 to:1 duration:duration done:^{
        done();
    }];
}
-(void)dismissWithDuration:(NSTimeInterval)duration callback:(void(^)())done {
    __weak id weakSelf = self;
    [self setClipScaleFrom:1 to:0.0001 duration:duration done:^{
        [weakSelf setHidden:YES];
        done();
    }];
}
-(void)setClipScaleFrom:(CGFloat)old to:(CGFloat)newScale duration:(NSTimeInterval)time done:(void(^)())done {
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(old, old, old)];
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(newScale, newScale, newScale)];
    anim.duration = time;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    self.clipLayer.transform = CATransform3DMakeScale(newScale, newScale, newScale);
    [self.clipLayer addAnimation:anim forKey:@"scale"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(anim.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        done();
    });
}

@end
