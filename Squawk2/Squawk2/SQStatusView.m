//
//  SQBlurredStatusView.m
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQStatusView.h"
#import "UIImage+ImageEffects.h"

@interface SQStatusViewCard () {
}

@property(strong)CALayer* circleMask;

@end


@implementation SQStatusViewCard

-(id)initWithText:(NSString*)text image:(UIImage*)image {
    self = [super init];
    
    //self.backgroundColor = [UIColor blackColor];
    //self.layer.cornerRadius = 10;
    
    //self.layer.borderWidth = 2;
    //self.layer.borderColor = [UIColor blackColor].CGColor;
    
    _label = [UILabel new];
    [self addSubview:_label];
    _label.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14];
    _label.text = text.uppercaseString;
    //_label.preferredMaxLayoutWidth = 150;
    _label.textAlignment = NSTextAlignmentLeft;
    //_label.numberOfLines = 0;
    //_label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.textColor = [UIColor whiteColor];
    
    /*_imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _imageView.tintColor = [UIColor blackColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_imageView];*/
    
    return self;
}
-(void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = CGRectInset(self.bounds, 10, 0);
}
-(void)setCircleSpeed:(CGFloat)circleSpeed {
    _circleSpeed = circleSpeed;
}
-(void)setCircleScale:(CGFloat)circleScale {
    _circleScale = circleScale;
}

@end



@interface SQStatusView () {
    NSMutableArray* _viewIdentifiers;
    NSMutableDictionary* _viewsForIdentifiers;
    UIImageView* _imageView;
    
    UITapGestureRecognizer* _gestureRec;
}

@property(weak,nonatomic)NSString* identifierForCurrentStatusView;

@end


@implementation SQStatusView

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
        
        // shift the text to the side opposite where the user touched, so they don't block it:
        newCurrentView.label.textAlignment = self.touchPoint.x < self.bounds.size.width/2? NSTextAlignmentRight : NSTextAlignmentLeft;
    }
    
    [self setVisible:!!identifierForCurrentStatusView];
}
-(void)setup {
    if (!_circles) {
        _circles = [WSConcentricCirclesViewAdvancedHD2014 new];
        _circles.delegate = self;
        [self insertSubview:_circles atIndex:0];
        
        self.clipsToBounds = YES;
    }
}
-(void)setVisible:(BOOL)visible {
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
        [self setup];
        
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
    } else {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.alpha = 1;
            self.hidden = YES;
        }];
    }
}
-(void)layoutSubviews {
    [super layoutSubviews];
    
    _circles.frame = self.bounds;
    
    SQStatusViewCard* currentStatusView = nil;
    if (self.identifierForCurrentStatusView) {
        currentStatusView = _viewsForIdentifiers[_identifierForCurrentStatusView];
        currentStatusView.frame = self.bounds;
    }
}
-(void)dismiss {
    for (NSString* identifier in _viewIdentifiers.copy) {
        [self removeStatusViewWithIdentifier:identifier];
    }
}

-(SQStatusViewCard*)currentView {
    return _viewIdentifiers.lastObject? _viewsForIdentifiers[_viewIdentifiers.lastObject] : nil;
}
-(CGFloat)concentricCirclesViewSpeed:(WSConcentricCirclesViewAdvancedHD2014 *)view {
    return self.currentView? self.currentView.circleSpeed : WSConcentricCirclesViewAdvancedHD2014Hidden;
}
-(void)setTouchPoint:(CGPoint)touchPoint {
    _touchPoint = touchPoint;
    [self setup];
    _circles.centerPoint = [_circles convertPoint:touchPoint fromView:self];
    [_circles update];
}

@end
