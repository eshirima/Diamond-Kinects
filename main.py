# main.py
# Emil Shirima
# 20-September-2019 8:46 PM
# 
# Purpose: Graph Swing data

import csv
import matplotlib.pyplot as plt

time_stamps, acclX, acclY, acclZ = [], [], [], []

# extracts data from file and saves it on the containers
def populate_data(file_name='latestSwing.csv'):
    with open(file_name) as csv_file:
        reader = csv.reader(csv_file)

        for data_point in reader:
            time_stamps.append(data_point[0])
            acclX.append(data_point[1])
            acclY.append(data_point[2])
            acclZ.append(data_point[3])

    csv_file.close()

# graphs data of each respective axis separately
def graph(time, x_data, y_data, z_data, title):

    plt.subplot(3, 1, 1)
    plt.title(title)
    plt.plot(time, x_data, 'r')
    plt.xlabel('Time')
    plt.ylabel('X-Axis')

    plt.subplot(3, 1, 2)
    plt.plot(time, y_data, 'g')
    plt.xlabel('Time')
    plt.ylabel('Y-Axis')

    plt.subplot(3, 1, 3)
    plt.plot(time, z_data, 'y')
    plt.xlabel('Time')
    plt.ylabel('Z-Axis')

    plt.show()

# graph all axes on same graph with count/index as x-axis values
def graph_indices(time, x_data, y_data, z_data, title):

    time = range(len(time))

    plt.title(title)

    plt.plot(time, x_data, 'r')
    plt.plot(time, y_data, 'g')
    plt.plot(time, z_data, 'y')

    plt.legend(['x-axis', 'y-axis', 'z-axis'])
    plt.ylabel('Values')
    plt.xlabel('Count')

    plt.show()

populate_data()
graph(time_stamps, acclX, acclY, acclZ, 'Acceleration')
graph_indices(time_stamps, acclX, acclY, acclZ, 'Acceleration')