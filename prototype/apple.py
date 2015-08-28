__author__ = 'asos'

from DataConverter import parse_csv, get_all_files

if __name__ == '__main__':

    trainpath = "valid_data/all/" #open(argv[1])
    testpath = "valid_data/7/" #open(argv[2])
    train_f = get_all_files(trainpath)
    test_f = get_all_files(testpath)

    data = []
    for f in train_f:
        data = data + parse_csv(trainpath+f)

    for f in test_f:
        data = data + parse_csv(testpath+f)

    print("data:", len(data))

    apple = ""
    mapping = {"Run" : "running",
           "Walk" : "walking",
           "Stand" : "stationary",
           "Automotive" : "automotive",
           "Shake" : "(null)",
           "Bicycle" : "automotive",
           "Train" : "(null)"
    }

    successes = 0
    fails = 0

    for record in data :
        sensor = record[1]
        activity = record[2]
        if sensor == "Activity":
            try:
                if len(record[7]) > 0:
                    apple = record[7]
                else:
                    raise Exception("I know python!")
            except:
                apple = record[6]

        if mapping[activity] == apple or apple == "(null)":
            successes += 1
        else:
            fails += 1

    print(successes)
    print(fails)

    print(successes/(successes+fails))