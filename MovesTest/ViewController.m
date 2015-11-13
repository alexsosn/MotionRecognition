//
//  ViewController.m
//  MovesTest
//
//  Created by Sosnovshchenko Alexander on 8/22/14.
//  Copyright (c) 2014 Sosnovshchenko Alexander. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>

#import "Lbimproved.h"

typedef NS_ENUM (NSInteger, SensorsEnum) {
    gyro = 0,
    acc,
	mag,
    mot,
    NUMBER_OF_SENSORS
};

static NSString * const kFolderPath = @"/MyFolder";
static const CGFloat kPeriod = 0.2;

@interface ViewController () <AVAudioPlayerDelegate, UITextFieldDelegate> {
    AVAudioPlayer* _audioPlayer;
}

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton* deletLogBtn;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;

@property (nonatomic, strong) CMMotionManager *mm;
@property (nonatomic, strong) CMMotionActivityManager *mam;
@property (nonatomic, strong) CMStepCounter *sc;

@property (nonatomic, strong) NSMutableArray *buffer;
@property (nonatomic, assign) NSUInteger counter;

@property (nonatomic, strong) NSDate *currentDate;

- (IBAction)recordPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;

@property (nonatomic, strong) NSMutableArray *acc_buffer;
@property (nonatomic, strong) NSMutableArray *gyro_buffer;

@property (nonatomic) double accValue;
@property (nonatomic) double gyroValue;

@property (nonatomic) BOOL recording;

@end

@implementation ViewController

-(NSDate *)currentDate {
    if (!_currentDate) {
        _currentDate = [NSDate date];
    }
    return _currentDate;
}

-(NSMutableArray *)acc_buffer {
    if (!_acc_buffer) {
        _acc_buffer = [NSMutableArray array];
    }
    return _acc_buffer;
}

-(NSMutableArray *)gyro_buffer {
    if (!_gyro_buffer) {
        _gyro_buffer = [NSMutableArray array];
    }
    return _gyro_buffer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textField.delegate = self;
    self.mm = [CMMotionManager new];
    [_mm setGyroUpdateInterval:kPeriod];
    [_mm setDeviceMotionUpdateInterval:kPeriod];
    [_mm setMagnetometerUpdateInterval:kPeriod];
    [_mm setAccelerometerUpdateInterval:kPeriod];
    
    self.mam = [CMMotionActivityManager new];
    self.sc = [CMStepCounter new];
    
    self.buffer = [NSMutableArray array];
    
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"track1" ofType:@"caf"]];

    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    _audioPlayer.numberOfLoops = -1;
    _audioPlayer.delegate = self;
    [_audioPlayer setVolume:0.0];
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
    
    [self startSampling];
    [self blockUI:YES];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
}

- (void)blockUI:(BOOL )block {
    if (block) {
        _deletLogBtn.enabled = NO;
    }else {
        _deletLogBtn.enabled = YES;
    }
}

- (IBAction)recordPressed:(id)sender {
    self.recording = YES;

    self.startBtn.selected = !self.startBtn.selected;
    if (self.recording) {
        [self startSampling];
        [self blockUI:YES];
    } else {
        _startBtn.enabled = NO;
        [self stopSampling];
        [self blockUI:NO];
        _startBtn.enabled = YES;
    }
}

- (IBAction)deletePressed:(id)sender {
    NSString *filePath = [self pathForType:0];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] &&
        [[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
        if (!err) {
            return;
        }
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:@"Can't delete log."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (NSArray *)pathes {
    return @[[NSString stringWithFormat:@"/data-%f.csv", self.currentDate.timeIntervalSince1970]];
}

- (NSString *)pathForFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:kFolderPath];
    return dataPath;
}

- (NSString *)pathForType:(SensorsEnum)sensor {
    NSString *path = [self pathes][0];
    NSString *filePath = [[self pathForFolder] stringByAppendingString:path];
    return filePath;
}

-(void)createFile {
    NSError *error = nil;
    self.currentDate = [NSDate date];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self pathForFolder]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self pathForFolder] withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
    for (NSInteger i = 0; i < NUMBER_OF_SENSORS; i++) {
        NSString *filePath = [self pathForType:i];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        }
    }
}

-(void)checkBuffer {
    NSLock *lock = [NSLock new];
    [lock lock];
    if ((self.acc_buffer.count >= 10) && (self.gyro_buffer.count >= 10)) {
        
        NSArray *acc = [[self.acc_buffer copy] subarrayWithRange: NSMakeRange( 0, 10 )];
        self.acc_buffer = nil;
        
        NSArray *gyro = [[self.gyro_buffer copy] subarrayWithRange: NSMakeRange( 0, 10 )];
        self.gyro_buffer = nil;
        
        NSString *result = [Lbimproved getSequenceTypeWithAccelerometer:acc gyroscopeArray:gyro];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityLabel.text = [NSString stringWithFormat:@"%@", result];
        });
    }
    [lock unlock];
}

-(void)startSampling {
    [self loadData];
    
    if (self.recording) {
        [self createFile];
    }
    
    NSOperationQueue *allQueue = [NSOperationQueue new];
    
    __block __weak typeof(self) despicableMe = self;
    
    if ([_mm isGyroAvailable] && ![_mm isGyroActive]) {
        
        [_mm startGyroUpdatesToQueue:allQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
            CMRotationRate rate = gyroData.rotationRate;
            
            _gyroValue = sqrt(pow(rate.x,2) + pow(rate.y,2) + pow(rate.z,2));
            
            NSString *str = [NSString stringWithFormat:@"%@,%@,%f,%f\n",
                             @([[NSDate date] timeIntervalSince1970]),
                             [despicableMe generateMove],
                             _accValue,
                             _gyroValue];
            
            if (self.recording) {
                [despicableMe addToBuffer:str];
            }
            
            [self.gyro_buffer addObject:@(_gyroValue)];
            [self checkBuffer];
        }];
    }
    
    if ([_mm isAccelerometerAvailable] && ![_mm isAccelerometerActive]) {
        [_mm startAccelerometerUpdatesToQueue:allQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            CMAcceleration acceleration = accelerometerData.acceleration;
            
            _accValue = sqrt(pow(acceleration.x,2) + pow(acceleration.y,2) + pow(acceleration.z,2));
            
            NSString *str = [NSString stringWithFormat:@"%@,%@,%f,%f\n",
                             @([[NSDate date] timeIntervalSince1970]),
                             [despicableMe generateMove],
                             _accValue,
                             _gyroValue];
            
            if (self.recording) {
                [despicableMe addToBuffer:str];
            }
            
            [self.acc_buffer addObject:@(_accValue)];
            [self checkBuffer];
        }];
    }
    /* 
     //apple default motion detection
     
    if ([[_mam class] isActivityAvailable]) {
        [_mam startActivityUpdatesToQueue:allQueue withHandler:^(CMMotionActivity *activity)
         {
             NSString *actType = nil;
             if (activity.unknown) {
                 actType = @"unknown";
             } else if (activity.stationary){
                 actType = @"stationary";
             } else if (activity.walking){
                 actType = @"walking";
             } else if (activity.running){
                 actType = @"running";
             } else if (activity.automotive){
                 actType = @"automotive";
             }
         }];
        
    }
    
    if ([[_sc class] isStepCountingAvailable]) {
        [_sc startStepCountingUpdatesToQueue:allQueue
                                    updateOn:1
                                 withHandler:^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error) {
                                     //NSString *str = [NSString stringWithFormat:@"%@,Steps,%@,%@\n",@([timestamp timeIntervalSince1970]),[self generateMove], @(numberOfSteps)];
                                     
                                     //[despicableMe addToBuffer:str];
                                     
                                     NSString *steps = [NSString stringWithFormat:@"%@", @(numberOfSteps)];
                                     dispatch_async(dispatch_get_main_queue(), ^{
//                                         self.stepsLabel.text = steps;
                                     });
                                 }];
     
    }
*/
}

- (NSString *)generateMove {
    NSString* moveType = self.textField.text;

    return moveType;
}

-(void)addToBuffer:(NSString *)str {
    [self.buffer addObject:str];
    self.counter ++;
    if (self.counter > 1000) {
        self.counter = 0;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.stateLabel.text = @"saving";
//        });
        
        [self saveData];
    }
}

-(void)stopSampling {
    [_mm stopGyroUpdates];
    [_mm stopDeviceMotionUpdates];
    [_mm stopMagnetometerUpdates];
    [_mm stopAccelerometerUpdates];
    [_mam stopActivityUpdates];
    [_sc stopStepCountingUpdates];
    [self saveData];
}

-(void)saveData {
    NSError *error = nil;
    NSString *path = [self pathForType:acc];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSArray *tempArray = [self.buffer copy];
        for (NSString *str in tempArray) {
            [self putArrayString:str];
        }
        NSLock *lock = [NSLock new];
        [lock lock];
        [self.buffer removeObjectsInArray:tempArray];
        [lock unlock];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.stateLabel.text = @":)";
//        });
    }
    if (error) {
        NSLog(@"%@",error);
    }
}

- (void)putArrayString:(NSString *)string
{
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[self pathForType:0]];
    [fh seekToEndOfFile];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [fh writeData:data];
    [fh closeFile];
}

- (void)loadData
{
    NSString *path = [self pathForFolder];
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
//    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"csv" inDirectory:@"Data"];
    
    for (NSString *filePath in paths)
    {
        NSLog(@"File %@", path);
        [Lbimproved loadFileWithPath:path];

        [Lbimproved loadFileWithPath:[path stringByAppendingPathComponent:filePath]];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
