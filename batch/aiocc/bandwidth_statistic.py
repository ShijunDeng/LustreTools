# description:    calculate the stddevvar and mean value of bandwidth
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-06
#
import numpy as np
import sys

# input_file = "data"
# output_file = "out"
input_file = sys.argv[1]
output_file = sys.argv[2]
global bandwidth_stddev
global bandwidth_mean
with open(input_file, 'r') as bandwidth_record_reader:
    bandwidth_record_line = bandwidth_record_reader.readline()
    bandwidth_record = np.array(bandwidth_record_line.split(" ")).astype(np.float)
    bandwidth_stddev = np.std(bandwidth_record)
    bandwidth_mean = np.mean(bandwidth_record)
with open(output_file, "w") as bandwidth_stat_writer:
    bandwidth_stat_writer.writelines("bandwidth_stddev:" + str(bandwidth_stddev) + "\n" + "bandwidth_mean:" + str(bandwidth_mean))
