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

typedef NS_ENUM(NSInteger, TypeOfMove) {
   TypeOfMoveWalk = 0,
   TypeOfMoveRun
};
typedef NS_ENUM(NSInteger, TypeOfDirections) {
    TypeOfDirectionsRoad = 0,
    TypeOfDirectionsUpstairs,
    TypeOfDirectionsDownstairs
};

typedef NS_ENUM(NSInteger, TypeOfPositonPhone) {
    TypeOfPositonPhonePocket = 0,
    TypeOfPositonPhonePalm,
    TypeOfPositonPhoneOnArm,
    TypeOfPositonPhoneBag
};

typedef NS_ENUM(NSInteger, TypeOfMoveFast) {
    TypeOfMoveFastBicycle = 0,
    TypeOfMoveFastTrain,
    TypeOfMoveFastAutomotive
};

typedef NS_ENUM(NSInteger, TypeOfStress) {
    TypeOfStressStand = 0,
    TypeOfStressShake
};

static NSString * const kFolderPath = @"/MyFolder";
static const CGFloat kPeriod = 0.2;

@interface ViewController () <AVAudioPlayerDelegate> {
    TypeOfMove _move;
    TypeOfDirections _direction;
    TypeOfPositonPhone _position;
    AVAudioPlayer* _audioPlayer;
}

@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton* deletLogBtn;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepsLabel;

@property (nonatomic, strong) CMMotionManager *mm;
@property (nonatomic, strong) CMMotionActivityManager *mam;
@property (nonatomic, strong) CMStepCounter *sc;

@property (nonatomic, strong) NSMutableArray *buffer;
@property (nonatomic, assign) NSUInteger counter;

@property (nonatomic, strong) NSDate *currentDate;

- (IBAction)startPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *walk_runSC;
@property (weak, nonatomic) IBOutlet UISegmentedControl *stairs_roadSC;
@property (weak, nonatomic) IBOutlet UISegmentedControl *onBodySC;

@property (weak, nonatomic) IBOutlet UISegmentedControl *transportSC;
@property (weak, nonatomic) IBOutlet UISegmentedControl *stand_shakeSC;
@property (weak, nonatomic) IBOutlet UISwitch *isRecordSwitch;

- (IBAction)walk_runAction:(id)sender;
- (IBAction)stairs_roadAction:(id)sender;
- (IBAction)onBodyAction:(id)sender;

- (IBAction)transportAction:(id)sender;
- (IBAction)standShakeAction:(id)sender;

@property (nonatomic, strong) NSMutableArray *acc_buffer;
@property (nonatomic, strong) NSMutableArray *gyro_buffer;

@property (nonatomic) double accValue;
@property (nonatomic) double gyroValue;

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
    self.mm = [CMMotionManager new];
    [_mm setGyroUpdateInterval:kPeriod];
    [_mm setDeviceMotionUpdateInterval:kPeriod];
    [_mm setMagnetometerUpdateInterval:kPeriod];
    [_mm setAccelerometerUpdateInterval:kPeriod];
    
    self.mam = [CMMotionActivityManager new];
    self.sc = [CMStepCounter new];
    
    self.buffer = [NSMutableArray array];
    [self deselectAllButton];
    
    
    
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
    

}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
}

- (void)deselectAllButton {
    [_walk_runSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stairs_roadSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_onBodySC  setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_transportSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stand_shakeSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

- (void)blockUI:(BOOL )block {
    if (block) {
        _walk_runSC.enabled = NO;
        _stairs_roadSC.enabled = NO;
        _onBodySC.enabled = NO;
        _transportSC.enabled = NO;
        _stand_shakeSC.enabled = NO;
        _deletLogBtn.enabled = NO;
    }else {
        _walk_runSC.enabled = YES;
        _stairs_roadSC.enabled = YES;
        _onBodySC.enabled = YES;
        _transportSC.enabled = YES;
        _stand_shakeSC.enabled = YES;
        _deletLogBtn.enabled = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPressed:(id)sender {
    self.startBtn.selected = !self.startBtn.selected;
    if (self.startBtn.selected) {
        [self startWrite];
        [self blockUI:YES];
    } else {
        _startBtn.enabled = NO;
        [self stopWrite];
        [self blockUI:NO];
        _startBtn.enabled = YES;
    }
    
    if ([_isRecordSwitch isOn]) {
        self.stateLabel.text = @"recording";
    }
    else {
        self.stateLabel.text = @"detecting";
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

-(NSArray *)pathes {
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

-(void)startWrite {
    [self loadData];
    
    [self createFile];
    
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
            
            if ([_isRecordSwitch isOn]) {
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
            
            if ([_isRecordSwitch isOn]) {
                [despicableMe addToBuffer:str];
            }
            
            [self.acc_buffer addObject:@(_accValue)];
            [self checkBuffer];
        }];
    }
    
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
             
//             NSString *str = [NSString stringWithFormat:@"%f,Activity,%@,,,,%@,%@\n",
//                              activity.startDate.timeIntervalSince1970,
//                              [self generateMove],
//                              @(activity.confidence),
//                              actType
//                              ];
//             [despicableMe addToBuffer:str];
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 self.activityLabel.text = [NSString stringWithFormat:@"%@ (%@)", actType, @(activity.confidence)];
//             });
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
                                         self.stepsLabel.text = steps;
                                     });
                                 }];
    }
}

- (NSString *)generateMove {
    NSString* moveType;
    if(_transportSC.selectedSegmentIndex == TypeOfMoveFastAutomotive || _transportSC.selectedSegmentIndex == TypeOfMoveFastBicycle || _transportSC.selectedSegmentIndex == TypeOfMoveFastTrain) {
        if(_transportSC.selectedSegmentIndex == TypeOfMoveFastAutomotive){
            moveType = @"Automotive,,";
        }else if(_transportSC.selectedSegmentIndex == TypeOfMoveFastBicycle){
            moveType = @"Bicycle,,";
        }else {
            moveType = @"Train,,";
        }
        
    }else if(_stand_shakeSC.selectedSegmentIndex == TypeOfStressShake || _stand_shakeSC.selectedSegmentIndex == TypeOfStressStand) {
        if(_stand_shakeSC.selectedSegmentIndex == TypeOfStressShake) {
            moveType = @"Shake,,";
        }else {
            moveType = @"Stand,,";
        }
        
    }else {
        moveType = [self generateWalkString];
    }

    return moveType;
}

- (NSString* )generateWalkString {
    NSString* result;
    if(_walk_runSC.selectedSegmentIndex == TypeOfMoveRun) {
        result = [NSString stringWithFormat:@"Run"];
    }else {
        result = [NSString stringWithFormat:@"Walk"];
        [_walk_runSC setSelectedSegmentIndex:TypeOfMoveWalk];
    }
    
    
    if(_stairs_roadSC.selectedSegmentIndex == TypeOfDirectionsDownstairs){
        result = [NSString stringWithFormat:@"%@,Downstairs", result];
    }else if (_stairs_roadSC.selectedSegmentIndex == TypeOfDirectionsUpstairs) {
        result = [NSString stringWithFormat:@"%@,Upstairs", result];
    }else {
        result = [NSString stringWithFormat:@"%@,Along the road", result];
        [_stairs_roadSC setSelectedSegmentIndex:TypeOfDirectionsRoad];
    }
    
    if(_onBodySC.selectedSegmentIndex == TypeOfPositonPhoneOnArm){
        result = [NSString stringWithFormat:@"%@,On arm", result];
    }else if (_onBodySC.selectedSegmentIndex == TypeOfPositonPhoneBag) {
        result = [NSString stringWithFormat:@"%@,Bag", result];
    }else if(_onBodySC.selectedSegmentIndex == TypeOfPositonPhonePocket){
        result = [NSString stringWithFormat:@"%@,Pocket", result];
    }else {
        result = [NSString stringWithFormat:@"%@,Palm", result];
        [_onBodySC setSelectedSegmentIndex:TypeOfPositonPhonePalm];
    }
    return result;
}

-(void)addToBuffer:(NSString *)str {
    [self.buffer addObject:str];
    self.counter ++;
    if (self.counter > 1000) {
        self.counter = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stateLabel.text = @"saving";
        });
        
        [self saveData];
    }
}

-(void)stopWrite {
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
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stateLabel.text = @":)";
        });
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
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    
    uint count = [directoryContent count];
    
    for (int i = 0; i < count; i++)
    {
        NSString *filePath = [directoryContent objectAtIndex:i];
        
        NSLog(@"File %d: %@", i, filePath);
        [Lbimproved loadFileWithPath:[path stringByAppendingPathComponent:filePath]];
    }
}

- (IBAction)walk_runAction:(id)sender {
    [_transportSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stand_shakeSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

- (IBAction)stairs_roadAction:(id)sender {
    [_transportSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stand_shakeSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

- (IBAction)onBodyAction:(id)sender {
    [_transportSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stand_shakeSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

- (IBAction)transportAction:(id)sender {
    [_stand_shakeSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_walk_runSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stairs_roadSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_onBodySC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

- (IBAction)standShakeAction:(id)sender {
    [_walk_runSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_stairs_roadSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_onBodySC setSelectedSegmentIndex:UISegmentedControlNoSegment];
    [_transportSC setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

@end
