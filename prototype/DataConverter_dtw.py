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

# mapping = {"Run" : "running",
#            "Walk" : "walking",
#            "Stand" : "stationary",
#            "Automotive" : "automotive",
#            "Shake" : "(null)",
#            "Bicycle" : "automotive",
#            "Train" : "(null)"
# }
#
# successes = 0
# fails = 0

def mapper(record):
    timestamp = float(record[0])
    try:
        date = datetime.datetime.fromtimestamp(
            (timestamp)
        )
    except:
        print(timestamp)

    # sensor = record[1]
    # activity = record[2]
    # apple = ""
    # if sensor == "Activity":
    #     try:
    #         if len(record[7]) > 0:
    #             apple = record[7]
    #         else:
    #             raise Exception("I know python!")
    #     except:
    #         apple = record[6]
    #
    # if mapping[activity] == apple or apple == "(null)":
    #     global successes
    #     successes += 1
    # else:
    #     global fails
    #     fails += 1

    mr.emit_intermediate(date.strftime('%Y-%m-%d %H:%M:%S'), record)

def magnitude (x,y,z):
    x = float(x)
    y = float(y)
    z = float(z)
    return sqrt(x**2 + y**2 + z**2)

def reducer(key, list_of_values):

    acc = []
    gyro = []
    motypes = []

    for el in list_of_values :
        magn = 0
        try :
            magn = magnitude(el[5], el[6], el[7])
        except:
            pass
        try:
            motypes.append(el[2])
        except:
            pass

        if el[1] == "Acceleration":
            acc.append(magn)
        if el[1] == "Gyroscope" or el[1] == "Gyro":
            gyro.append(magn)

    words_to_count = (word for word in motypes)
    c = Counter(words_to_count)
    motype = c.most_common()[0][0]

    if len(acc) > 1 and len(gyro) > 1:
        mr.emit({
            'date':key,
            'activity':motype,
            'acc':mean(acc),
            'gyro':mean(gyro)}
        )

HEADERS = ['date', 'activity', 'acc', 'gyro']

if __name__ == '__main__':

    trainpath = "valid_data/all/" #open(argv[1])
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

    with open('out_train_dtw.csv',  mode='w', encoding='utf-8') as csvfile:
        csvwriter = csv.DictWriter(csvfile, delimiter=',',
                                quotechar='"', quoting=csv.QUOTE_MINIMAL,
                                fieldnames = HEADERS)
        csvwriter.writeheader()
        for r in aggregated_train:
            csvwriter.writerow(r)
    print('train output done: "out_train_dtw.csv"')

    mr = MapReduce.MapReduce()

    aggregated_test = mr.execute(test_data, mapper, reducer)
    print("test aggregation done")

    with open('out_test_dtw.csv',  mode='w', encoding='utf-8') as csvfile:
        csvwriter = csv.DictWriter(csvfile, delimiter=',',
                                quotechar='"', quoting=csv.QUOTE_MINIMAL,
                                fieldnames = HEADERS)
        csvwriter.writeheader()
        for r in aggregated_test:
            csvwriter.writerow(r)
    print('test output done: "out_test_dtw.csv"')
    # print(successes)
    # print(fails)
    #
    # print(successes/(successes+fails))
