//
//  lbimproved.mm
//  TestLbimproved
//
//  Created by Korol Viktor on 9/24/14.
//  Copyright (c) 2014 Ciklum. All rights reserved.
//
#import "lbimproved.h"
#include "lbimproved/dtw.h"
#include <fstream>
#include <string>
#include <map>

class ChunksParser
{
public:
    ChunksParser(uint chunkSize) :
        chunkSize(chunkSize)
    {
        
    }
    
    void parse(const char *path, uint activityColumn, uint accColumn, uint gyroColumn)
    {
        std::string activityType;
        std::vector<double> acc;
        std::vector<double> gyro;
        
        // open a file in read mode.
        ifstream infile;
        
        infile.open(path);
        
        std::string line;
        
        // skip header
        std::getline(infile, line);
        std::getline(infile, line);
        
        while (line != "") {
            std::vector<std::string> items;
            std::stringstream ss(line);
            std::string s;
            
            while (getline(ss, s, ',')) {
                // remove front quote
                if (s.front() == '"') {
                    s.erase(0, 1);
                }

                // remove back quote
                if (s.back() == '"') {
                    s.erase(s.size() - 1);
                }
                
                items.push_back(s);
            }
            
            std::stringstream sAccValue(items[accColumn]);
            double accValue;
            
            sAccValue >> accValue;
            
            std::stringstream sGyroValue(items[gyroColumn]);
            double gyroValue;
            
            sGyroValue >> gyroValue;
            
            acc.push_back(accValue);
            gyro.push_back(gyroValue);
            activityType = items[activityColumn];
            
            std::getline(infile, line);
        };
    
        uint offset = 0;

        while (acc.size() >= offset + chunkSize &&
               gyro.size() >= offset + chunkSize)
        {
            Chunk chunk;
            
            chunk.acc.assign(acc.begin() + offset, acc.begin() + offset + chunkSize);
            chunk.gyro.assign(gyro.begin() + offset, gyro.begin() + offset + chunkSize);
            chunk.activityType = activityType;
            
            chunks.push_back(chunk);
            
            offset += chunkSize;
        }

        acc.clear();
        gyro.clear();
    }

    void check() {
        dtw d(chunkSize, 0.1);
        uint matchCount = 0;
        uint matchAccCount = 0;
        uint matchGyroCount = 0;
        
        for (ChunksVector::iterator sample = chunks.begin(); sample != chunks.end(); ++sample)
        {
            std::string minActivityType;
            std::string minAccActivityType;
            std::string minGyroActivityType;
            
            double minFD = DBL_MAX;
            double minFDAcc = DBL_MAX;
            double minFDGyro = DBL_MAX;
            
            for (ChunksVector::iterator next = chunks.begin(); next != chunks.end(); ++next)
            {
                double fdAcc = d.fastdynamic(sample->acc, next->acc) / chunkSize;
                double fdGyro = d.fastdynamic(sample->gyro, next->gyro) / chunkSize;
                
                {
                    double fd = fdAcc + fdGyro;
                    
                    if (fd != 0 && fd < minFD) {
                        minFD = fd;
                        
                        minActivityType = next->activityType;
                    }
                }
                
                {
                    if (fdAcc != 0 && fdAcc < minFDAcc) {
                        minFDAcc = fdAcc;
                        
                        minAccActivityType = next->activityType;
                    }
                }
                
                {
                    if (fdGyro != 0 && fdGyro < minFDGyro) {
                        minFDGyro = fdGyro;
                        
                        minGyroActivityType = next->activityType;
                    }
                }
            }
            
            //std::cout << "fd = " << minFD << " " << minActivityType << std::endl;
            
            if (minActivityType == sample->activityType) {
                ++matchCount;
            }
            
            if (minAccActivityType == sample->activityType) {
                ++matchAccCount;
            }
            
            if (minGyroActivityType == sample->activityType) {
                ++matchGyroCount;
            }
        }
        
        std::cout << "match percent " << ((float)matchCount / chunks.size()) * 100 << std::endl;
        std::cout << "match acc percent " << ((float)matchAccCount / chunks.size()) * 100 << std::endl;
        std::cout << "match gyro percent " << ((float)matchGyroCount / chunks.size()) * 100 << std::endl << std::endl;
    }
    
    typedef struct knnResult {
        std::string name;
        double support;
    } KNNResult;
    
    KNNResult findMatch(uint count, std::vector<double> acc, std::vector<double> gyro) {
        dtw d(count, 0.1);
//        LB_Keogh model_acc(acc, 0.1);
//        LB_Keogh model_gyro(gyro, 0.1);

        std::string minActivityType;
        std::string minAccActivityType;
        std::string minGyroActivityType;
        
        std::vector<std::string> nearestNeighbors;
        
        double minFD = DBL_MAX;
//        double minFDAcc = DBL_MAX;
//        double minFDGyro = DBL_MAX;
        
        for (ChunksVector::iterator next = chunks.begin(); next != chunks.end(); ++next)
        {
//            double fdAcc = model_acc.NearestNeighbor::test(next->acc) / chunkSize;
//            double fdGyro = model_gyro.NearestNeighbor::test(next->gyro) / chunkSize;
            
            double fdAcc = d.fastdynamic(acc, next->acc) / chunkSize;
            double fdGyro = d.fastdynamic(gyro, next->gyro) / chunkSize;

            {
                double fd = fdAcc + fdGyro;
                
                if (fd != 0 && fd < minFD) {
                    minFD = fd;
                    nearestNeighbors.push_back(next->activityType);
                    if (nearestNeighbors.size() > 5) { // kNN, k == 5
                        nearestNeighbors.erase(nearestNeighbors.begin(), nearestNeighbors.begin() + 1);
                    }
//                    minActivityType = next->activityType;
                }
            }
            
//            {
//                if (fdAcc != 0 && fdAcc < minFDAcc) {
//                    minFDAcc = fdAcc;
//                    nearestNeighbors.push_back(next->activityType);
//                    if (nearestNeighbors.size() > 5) { // kNN, k == 5
//                        nearestNeighbors.erase(nearestNeighbors.begin(), nearestNeighbors.begin() + 1);
//                    }
////                    minAccActivityType = next->activityType;
//                }
//            }
//
//            {
//                if (fdGyro != 0 && fdGyro < minFDGyro) {
//                    minFDGyro = fdGyro;
//                    
//                    minGyroActivityType = next->activityType;
//                }
//            }
        }
        
        std::map<std::string , int> histogram;
        
        for (const string & s : nearestNeighbors) { ++histogram[s]; }
        
        double maxNeighbors = 0.0;
        std::string maxNeighborsActivityType;
        for (const auto & p : histogram)
        {
            if (p.second > maxNeighbors) {
                maxNeighbors = p.second;
                maxNeighborsActivityType = p.first;
            }
            std::cout << "Word '" << p.first << "' occurs " << p.second << " times.\n";
        }
        
        KNNResult res;
        res.name = maxNeighborsActivityType;
        res.support = maxNeighbors/5.0;
        
        return res;
    }
    
private:
    typedef struct tagChunk{
        std::vector<double> acc;
        std::vector<double> gyro;
        std::string activityType;
    } Chunk;
    
    typedef std::vector<Chunk> ChunksVector;
    
    ChunksVector chunks;
    uint chunkSize;
};

static ChunksParser parser(10);

@implementation Lbimproved

+ (void)loadFileWithPath:(NSString *)filePath;
{
    parser.parse([filePath cStringUsingEncoding:NSASCIIStringEncoding], 1, 4, 5);
}

+ (NSString *)getSequenceTypeWithAccelerometer:(NSArray *)acc_a gyroscopeArray:(NSArray *)gyro_a {
    std::vector<double> acc;
    std::vector<double> gyro;
    
    for (NSNumber *num in acc_a) {
        double magnitude = num.doubleValue;
        acc.push_back(magnitude);
        
    }
    
    for (NSNumber *num in gyro_a) {
        double magnitude = num.doubleValue;
        gyro.push_back(magnitude);
        
    }
    
    ChunksParser::KNNResult result = parser.findMatch((uint)gyro_a.count, acc, gyro);
    double support = result.support*100;
    std::string name = result.name;
    
    NSString *activity = [NSString stringWithCString:name.c_str()
                                                encoding:[NSString defaultCStringEncoding]];
    NSString *res = [NSString stringWithFormat:@"%@ %@%%", activity, @(support)];
    return res;
}

@end
