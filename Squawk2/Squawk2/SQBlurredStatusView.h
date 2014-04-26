//
//  SQBlurredStatusView.h
//  Squawk2
//
//  Created by Nate Parrott on 3/10/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQStatusViewCard : UIView

-(id)initWithText:(NSString*)text image:(UIImage*)image;
@property CGFloat animationSpeed;
@property(strong)UIImageView* imageView;
@property(strong)UILabel* label;

@property(nonatomic)CGFloat circleFill;
@property(nonatomic)CGFloat circleTurn;

@property(strong)CAShapeLayer *filledCircle, *emptyCircle;

@end


@interface SQBlurredStatusView : UIView {
}

@property(strong,nonatomic)IBOutlet UIView* underlyingView;
@property(strong,nonatomic)NSArray* passthroughRects;

-(void)addStatusView:(SQStatusViewCard*)statusView withIdentifier:(NSString*)identifier;
-(void)removeStatusViewWithIdentifier:(NSString*)identifier;
-(void)replaceStatusViewForIdentifier:(NSString*)identifier withStatusView:(SQStatusViewCard*)view;
-(void)flashStatusView:(SQStatusViewCard*)view duration:(NSTimeInterval)duration;
-(SQStatusViewCard*)viewForIdentifier:(NSString*)identifier;
-(SQStatusViewCard*)currentView;
@property(nonatomic) BOOL visible;

@end
