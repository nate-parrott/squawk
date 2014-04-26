//
//  iPadWelcomeViewController.m
//  Squawk
//
//  Created by Justin Brower on 1/26/14.
//  Copyright (c) 2014 Justin Brower. All rights reserved.
//

#import "IPadWelcomeViewController.h"

@interface IPadWelcomeViewController ()

@end

@implementation IPadWelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)awakeFromNib
{
    UIImage *image = [UIImage imageNamed:@"ipad-splash.png"];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.bounces = NO;
    [self.view addSubview:self.scrollView];
    
    //
    float resizedScale = self.view.frame.size.width / image.size.width;
    
    UIImageView *background = [[UIImageView alloc] initWithImage:image];
    background.frame = CGRectMake(0,0,self.view.frame.size.width,image.size.height*resizedScale);

    self.getSquawkin.alpha = 0;
    self.input.alpha = 0;
    self.input.delegate = self;
    
    
    [self.scrollView addSubview:background];
    [self.scrollView setBackgroundColor:[UIColor blueColor]];
    [self.scrollView setContentSize:background.frame.size];
    
    [self performSelector:@selector(animate:) withObject:nil afterDelay:1.0];
}

- (void)animate:(id)param
{
    [self.view bringSubviewToFront:self.getSquawkin];
    [self.view bringSubviewToFront:self.input];
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    [UIView animateWithDuration:1 animations:^{
        self.getSquawkin.alpha = 1;
        self.getSquawkin.enabled = NO;
        self.input.alpha = 1;
        [self.scrollView setContentOffset:CGPointMake(0,self.scrollView.contentSize.height - self.view.frame.size.height)];
    } completion:^(BOOL completed)
     {
         self.scrollView.scrollEnabled = NO;
         [self.input becomeFirstResponder];
         
         [self.getSquawkin addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
         
     }];
}



-(IBAction)textFieldChanged:(id)sender {
    self.getSquawkin.enabled = [self.input.text length] == 10;
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* newText = [self.input.text stringByReplacingCharactersInRange:range withString:string];
    self.getSquawkin.enabled = newText.length>=10;
    return YES;
}

- (void)done:(id)param
{
    NSString* num = [NPContact normalizePhone:self.input.text];
    [[NSUserDefaults standardUserDefaults] setObject:num forKey:@"PhoneNumber"];
    [[PFInstallation currentInstallation] setValue:num forKey:@"phoneNumber"];
    [[PFInstallation currentInstallation] saveInBackground];
    [[PFUser currentUser] setValue:num forKey:@"phoneNumber"];
    [[PFUser currentUser] saveInBackground];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kWSShouldReloadMessagesNotification" object:nil];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
