//
//  SQBlurredStatusView.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQBlurredStatusView.h"
#import "UIImage+ImageEffects.h"
#import "SQDopplerView.h"

@interface SQStatusViewCard () {
    CGFloat _lastCircleSize;
}

@property(strong)CALayer* circleMask;

@end


@implementation SQStatusViewCard

-(id)initWithText:(NSString*)text image:(UIImage*)image {
    self = [super init];
    
    self.filledCircle = [CAShapeLayer layer];
    self.emptyCircle = [CAShapeLayer layer];
    for (CAShapeLayer* layer in @[self.emptyCircle, self.filledCircle]) {
        layer.fillColor = nil;
        layer.strokeColor = [UIColor blackColor].CGColor;
        layer.lineWidth = 2;
        layer.strokeStart = 0;
        layer.strokeEnd = 1;
        [self.layer addSublayer:layer];
    }
    self.emptyCircle.opacity = 0.2;
    
    self.circleMask = [CALayer layer];
    self.circleMask.backgroundColor = [UIColor blackColor].CGColor;
    self.filledCircle.mask = self.circleMask;
    
    //self.backgroundColor = [UIColor blackColor];
    //self.layer.cornerRadius = 10;
    
    //self.layer.borderWidth = 2;
    //self.layer.borderColor = [UIColor blackColor].CGColor;
    
    _label = [UILabel new];
    [self addSubview:_label];
    _label.font = [UIFont fontWithName:@"AvenirNext-Medium" size:16];
    _label.alpha = 0.7;
    _label.text = text.uppercaseString;
    //_label.preferredMaxLayoutWidth = 150;
    _label.textAlignment = NSTextAlignmentCenter;
    _label.numberOfLines = 0;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    
    _imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _imageView.tintColor = [UIColor blackColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_imageView];
    
    _label.textColor = [UIColor blackColor];
    
    self.circleFill = 1;
    self.circleTurn = 0.0;
    
    return self;
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    //self.layer.cornerRadius = self.bounds.size.width/2;
    
    CGSize textSize = [_label.text sizeWithFont:_label.font forWidth:150 lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat imageSize = 90;
    CGFloat contentHeight = textSize.height + 5 + imageSize;
    CGFloat y = (self.bounds.size.height - contentHeight)/2;
    _imageView.frame = CGRectMake((self.bounds.size.width-imageSize)/2, y, imageSize, imageSize);
    y += imageSize + 5;
    _label.frame = CGRectMake((self.bounds.size.width-textSize.width)/2, y, textSize.width, textSize.height);

    CGFloat w = MIN(self.bounds.size.width, self.bounds.size.height);
    self.emptyCircle.bounds = self.filledCircle.bounds = CGRectMake(0, 0, w, w);
    self.emptyCircle.position = self.filledCircle.position = self.imageView.center;//CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.circleMask.frame = CGRectMake(0, self.emptyCircle.bounds.size.height*(1-self.circleFill), w, w*self.circleFill);
    
    if (w != _lastCircleSize) {
        _lastCircleSize = w;
        CGPathRef path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(w/2, w/2) radius:w/2-4 startAngle:0 endAngle:M_PI*2 clockwise:YES].CGPath;//[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, w, w)].CGPath;
        self.emptyCircle.path = self.filledCircle.path = path;
    }
}
-(void)setCircleFill:(CGFloat)circleFill {
    _circleFill = circleFill;
    [self layoutSubviews];
}
-(void)setCircleTurn:(CGFloat)circleTurn {
    _circleTurn = circleTurn;
    self.filledCircle.strokeEnd = circleTurn;
}

@end



@interface SQBlurredStatusView () {
    NSMutableArray* _viewIdentifiers;
    NSMutableDictionary* _viewsForIdentifiers;
    UIImageView* _imageView;
    
    UITapGestureRecognizer* _gestureRec;
    
    SQDopplerView* _dopplerView;
}

@property(weak,nonatomic)NSString* identifierForCurrentStatusView;

@end


@implementation SQBlurredStatusView

-(void)awakeFromNib {
    [super awakeFromNib];
    
    _dopplerView = [SQDopplerView new];
    [self addSubview:_dopplerView];
    _dopplerView.hidden = YES;
}
-(void)addStatusView:(SQStatusViewCard*)statusView withIdentifier:(NSString*)identifier {
    if (!_viewIdentifiers) {
        _viewIdentifiers = [NSMutableArray new];
        _viewsForIdentifiers = [NSMutableDictionary new];
    }
    if ([_viewIdentifiers containsObject:identifier]) return;
    [_viewIdentifiers addObject:identifier];
    _viewsForIdentifiers[identifier] = statusView;
    self.identifierForCurrentStatusView = identifier;
    [self setVisible:YES];
}
-(void)removeStatusViewWithIdentifier:(NSString*)identifier {
    if (![_viewIdentifiers containsObject:identifier]) return;
    [_viewIdentifiers removeObject:identifier];
    self.identifierForCurrentStatusView = _viewIdentifiers.lastObject;
    [_viewsForIdentifiers removeObjectForKey:identifier];
}
-(void)replaceStatusViewForIdentifier:(NSString*)identifier withStatusView:(SQStatusViewCard*)view {
    if (view==nil) {
        [self removeStatusViewWithIdentifier:identifier];
    } else if (view == _viewsForIdentifiers[identifier]) {
        return;
    } else {
        [_viewsForIdentifiers[identifier] removeFromSuperview];
        [_viewsForIdentifiers removeObjectForKey:identifier];
        [_viewIdentifiers removeObject:identifier];
        [self addStatusView:view withIdentifier:identifier];
    }
}
-(void)flashStatusView:(SQStatusViewCard*)view duration:(NSTimeInterval)duration {
    static int identifierCount = 0;
    NSString* identifier = [NSString stringWithFormat:@"__flash_%i", identifierCount++];
    [self addStatusView:view withIdentifier:identifier];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeStatusViewWithIdentifier:identifier];
    });
}
-(SQStatusViewCard*)viewForIdentifier:(NSString*)identifier {
    return _viewsForIdentifiers[identifier];
}
-(void)setIdentifierForCurrentStatusView:(NSString *)identifierForCurrentStatusView {
    
    SQStatusViewCard* currentView = _viewsForIdentifiers[_identifierForCurrentStatusView];
    if (currentView) {
        BOOL fadingOutEntireStatusView = identifierForCurrentStatusView==nil;
        if (fadingOutEntireStatusView) {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                currentView.alpha = 0;
            } completion:^(BOOL finished) {
                if (currentView != [self currentView]) {
                    currentView.alpha = 1;
                    [currentView removeFromSuperview];
                } else {
                    currentView.alpha = 1;
                }
            }];
        } else {
            [currentView removeFromSuperview];
        }
    }
    
    _identifierForCurrentStatusView = identifierForCurrentStatusView;
    
    SQStatusViewCard* newCurrentView = nil;
    if (identifierForCurrentStatusView) {
        newCurrentView = _viewsForIdentifiers[identifierForCurrentStatusView];
        [self addSubview:newCurrentView];
    }
    _dopplerView.outgoingSpeed = newCurrentView.animationSpeed*0.5;
    _dopplerView.animating = newCurrentView.animationSpeed!=0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _dopplerView.alpha = newCurrentView.animationSpeed? 0.7 : 0;
    } completion:^(BOOL finished) {
    }];
    
    [self setVisible:!!identifierForCurrentStatusView];
}
-(void)setUnderlyingView:(UIView *)underlyingView {
    _underlyingView = underlyingView;
    if (_visible) [self updateBlurView];
}
-(void)setVisible:(BOOL)visible {
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
        [self updateBlurViewWithCallback:^{
            self.hidden = NO;
            self.alpha = 0;
            self.currentView.transform = CGAffineTransformMakeScale(0.3, 0.3);
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.alpha = 1;
            } completion:^(BOOL finished) {
            }];
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.currentView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
            }];
        }];
    } else {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.alpha = 1;
            self.hidden = YES;
        }];
    }
}
-(void)setPassthroughRects:(NSArray *)passthroughRects {
    _passthroughRects = passthroughRects;
    if (_visible) [self updateBlurView];
}
-(void)updateBlurView {
    [self updateBlurViewWithCallback:nil];
}
-(UIImage*)imageForUnderlyingView {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, [UIScreen mainScreen].scale);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithRect:self.bounds] fill];
    [self.underlyingView drawViewHierarchyInRect:[self convertRect:self.underlyingView.bounds fromView:self.underlyingView] afterScreenUpdates:NO];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(void)updateBlurViewWithCallback:(void(^)())callback {
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage* imageForUnderlyingView = [self imageForUnderlyingView];
        // create passthrough mask:
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.1);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextAddRect(ctx, self.bounds);
        for (NSValue* rect in self.passthroughRects) {
            CGContextAddRect(ctx, rect.CGRectValue);
        }
        CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextEOFillPath(ctx);
        UIImage* mask = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // blur underlying view:
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
        
        // flip context:
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, -self.bounds.size.height);
        
        CGContextClipToMask(UIGraphicsGetCurrentContext(), self.bounds, mask.CGImage);
        
        // unflip:
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, self.bounds.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
        
        UIImage* toBlur = imageForUnderlyingView;
        UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        CGFloat saturationDelta = 1.8;
        UIImage* blurred = [toBlur applyBlurWithRadius:5 tintColor:tintColor saturationDeltaFactor:saturationDelta maskImage:nil];
        [blurred drawInRect:self.bounds];
        UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_imageView) {
                _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
                [self insertSubview:_imageView atIndex:0];
                _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            }
            _imageView.image = image;
            if (callback) callback();
        });
    //});
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    SQStatusViewCard* currentStatusView = nil;
    if (self.identifierForCurrentStatusView) {
        currentStatusView = _viewsForIdentifiers[_identifierForCurrentStatusView];
        //currentStatusView.frame = self.bounds;
        currentStatusView.bounds = CGRectMake(0, 0, 250, 250);
        currentStatusView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
    
    if (!CGSizeEqualToSize(_imageView.image.size, self.bounds.size)) {
        [self updateBlurView];
    }
    
    _dopplerView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    if (currentStatusView) {
        [currentStatusView layoutIfNeeded];
        _dopplerView.center = [self convertPoint:currentStatusView.imageView.center fromView:currentStatusView.imageView.superview];
    }
    _dopplerView.bounds = CGRectMake(0, 0, MIN(self.bounds.size.width, self.bounds.size.height), MIN(self.bounds.size.width, self.bounds.size.height));
}
-(void)dismiss {
    for (NSString* identifier in _viewIdentifiers.copy) {
        [self removeStatusViewWithIdentifier:identifier];
    }
}
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    [self dismiss];
    return NO;
    if (![super pointInside:point withEvent:event]) return NO;
    for (NSValue* rect in _passthroughRects) {
        if (CGRectContainsPoint(rect.CGRectValue, point)) {
            return NO;
        }
    }
    return YES;
}
-(SQStatusViewCard*)currentView {
    return _viewIdentifiers.lastObject? _viewsForIdentifiers[_viewIdentifiers.lastObject] : nil;
}
@end
