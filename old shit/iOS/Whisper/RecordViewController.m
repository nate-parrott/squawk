//
//  RecordViewController.m
//  Whisper
//
//  Created by Justin Brower on 1/24/14.
//  Copyright (c) 2014 Justin Brower. All rights reserved.
//

#import "RecordViewController.h"
#import "WSAppDelegate.h"

@interface RecordViewController ()

@end

@implementation RecordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}






//uploads the current output.acc file to parse
- (void)uploadOutputToServerWithRecipient:(NSString *)recipient duration:(float)duration{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *sender = [[NSUserDefaults standardUserDefaults] objectForKey:@"PhoneNumber"];
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
    
    //fields:
    //   senderPhoneNumber        string
    //   recipientPhoneNumber     string
    //   file                     file
    //   duration                 number
    //   listened                 BOOL
    
    PFFile *file = [PFFile fileWithData:[NSData dataWithContentsOfFile:filePath]];
    [file saveInBackground];
    
    PFObject *someObject = [PFObject objectWithClassName:@"Message"
                                     dictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 sender,@"senderPhoneNumber",
                                                              recipient,@"recipientPhoneNumber",
                    
                                                file,@"file",
                                    [NSNumber numberWithFloat:duration],@"duration",
                                                                    @NO,@"listened",nil]];
    
    [someObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (succeeded){
            
                [self.delegate recordViewDidCompleteUpload:self];
        }
        else{
                [self.delegate recordViewDidFailUpload:self withError:error];
        }
    }];
    PFQuery* query = [PFInstallation query];
    [query whereKey:@"phoneNumber" equalTo:recipient];
    [PFPush sendPushMessageToQueryInBackground:query withMessage:[NSString stringWithFormat:@"Squawk from %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"PhoneNumber"]]];
    
    PFQuery* userQuery = [PFUser query];
    [userQuery whereKey:@"phoneNumber" equalTo:recipient];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            [AppDelegate promptUserToJoin:recipient];
        }
    }];
    /*[query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSString* message = [NSString stringWithFormat:@"%@ isn't on Parrott.", recipient];
            [[[UIAlertView alloc] initWithTitle:@"Someone's missing out" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:@"Text them an invitation", nil] show];
        }
    }];*/
}

#pragma mark UI
-(IBAction)startRecording:(id)sender {
    
    //todo: configure the 'options' nsdictionary for audioRecorder
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:nil];
    [session setActive:YES error:nil];
    
    self.audioRecorder = nil;
    if ( !self.audioRecorder ){
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *writePath = [documentsDirectory stringByAppendingPathComponent:@"output.m4a"];
        
        NSDictionary *recordSettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC)};
        
        /*[recordSettings setObject:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        */
        
        
        NSError *error = nil;
        
        self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:writePath] settings:recordSettings error:&error];
        self.audioRecorder.delegate = self;
        
        if ( error ){
            [self.delegate recordViewDidFailRecord:self withError:error];
            return;
        }
        [self.audioRecorder prepareToRecord];
    }
    
    
    [self.audioRecorder recordForDuration:RECORDING_LENGTH];
    
}

-(IBAction)stopRecording:(id)sender {
    [self.audioRecorder stop];
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [self.delegate recordViewDidFinishRecording:self];
}



@end
