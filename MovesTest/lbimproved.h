//
//  lbimproved.h
//  TestLbimproved
//
//  Created by Korol Viktor on 9/24/14.
//  Copyright (c) 2014 Ciklum. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Lbimproved : NSObject

+ (NSString *)getSequenceTypeWithAccelerometer:(NSArray *)acc_a gyroscopeArray:(NSArray *)gyro_a;
+ (void)loadFileWithPath:(NSString *)filePath;

@end
