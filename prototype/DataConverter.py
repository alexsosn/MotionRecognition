__author__ = 'asos'
import MapReduce
import csv
from sys import argv
import datetime
from statistics import mean
from statistics import stdev
from math import sqrt
from numpy.fft import fft
from collections import Counter


from os import listdir

def get_all_files(path):
    f = []
    for file in listdir(path):
        if file.endswith(".csv"):
            f.append(file)
    return f

def parse_csv(filename):
    with open(filename, "rt", encoding="UTF-8") as csvfile:
        res = []
        csv_reader = csv.reader(csvfile, delimiter='\n', quotechar='"')
        for row in csv_reader:
            for col in row:
                res.append(col.split(','))
    return res

def mapper(record):
    timestamp = float(record[0])
    try:
        date = datetime.datetime.fromtimestamp(
            (timestamp)
        )
    except:
        print(timestamp)

    #sensor = record[1]
    for w in range(-1,1):
        date_res = date + datetime.timedelta(seconds=w)
        mr.emit_intermediate(date_res.strftime('%Y-%m-%d %H:%M:%S'), record)

def magnitude (x,y,z):
    x = float(x)
    y = float(y)
    z = float(z)
    return sqrt(x**2 + y**2 + z**2)

def reducer(key, list_of_values):
    print(key)
    acc = []
    gyro = []
    motypes = []

    for el in list_of_values :
        magn = 0
        try :
            magn = magnitude(el[5], el[6], el[7])
            print(magn)
        except:
            print("яzzzzь")
            pass
        try:
            motypes.append(el[2])
        except:
            pass

        if el[1] == "User_Acceleration":
            acc.append(magn)
        if el[1] == "Rotation_Rate":# or el[1] == "Gyro":
            gyro.append(magn)

    words_to_count = (word for word in motypes)
    c = Counter(words_to_count)
    motype = c.most_common()[0][0]

    if len(acc) > 1 and len(gyro) > 1:
        mr.emit({
            'date':key,
            'activity':motype,
            'mean_acc':mean(acc), 'mean_gyro':mean(gyro),
            'sd_acc':stdev(acc), 'sd_gyro':stdev(gyro),
            'min_acc':min(acc), 'min_gyro':min(gyro),
            'max_acc':max(acc), 'max_gyro':max(gyro),
            'fft_acc':max(abs(fft(acc))), 'fft_gyro':max(abs(fft(gyro)))
        })

HEADERS = ['date', 'activity', 'mean_acc', 'mean_gyro', 'sd_acc', 'sd_gyro',
           'min_acc', 'min_gyro', 'max_acc', 'max_gyro', 'fft_acc', 'fft_gyro']

if __name__ == '__main__':

    trainpath = "valid_data/8_android/"#"valid_data/all/" #open(argv[1])
    testpath = "valid_data/7/" #open(argv[2])
    train_f = get_all_files(trainpath)
    test_f = get_all_files(testpath)

    train_data = []
    test_data = []
    for f in train_f:
        train_data = train_data + parse_csv(trainpath+f)

    for f in test_f:
        test_data = test_data + parse_csv(testpath+f)

    print("train data:", len(train_data), "test data", len(test_data))

    mr = MapReduce.MapReduce()

    aggregated_train = mr.execute(train_data, mapper, reducer)
    print("train aggregation done")

    with open('out_train.csv',  mode='w', encoding='utf-8') as csvfile:
        csvwriter = csv.DictWriter(csvfile, delimiter=',',
                                quotechar='"', quoting=csv.QUOTE_MINIMAL,
                                fieldnames = HEADERS)
        csvwriter.writeheader()
        for r in aggregated_train:
            csvwriter.writerow(r)
    print('train output done: "out_train.csv"')

    mr = MapReduce.MapReduce()

    aggregated_test = mr.execute(test_data, mapper, reducer)
    print("test aggregation done")

    with open('out_test.csv',  mode='w', encoding='utf-8') as csvfile:
        csvwriter = csv.DictWriter(csvfile, delimiter=',',
                                quotechar='"', quoting=csv.QUOTE_MINIMAL,
                                fieldnames = HEADERS)
        csvwriter.writeheader()
        for r in aggregated_test:
            csvwriter.writerow(r)
    print('test output done: "out_test.csv"')
