#!/usr/bin/python3

import glob
import matplotlib.pyplot as plt
import datetime
import sys
import re

def plot_bandwidth(file_pattern, output_name, benchmark_name):
    # Get the list of files matching the pattern
    files = glob.glob(file_pattern)
    # Sort files based on the qps value in the file name
    #iles.sort(key=lambda x: int(re.search(r'(\d+)qps', x).group(1)))

    # Initialize lists to store data
    byte_list = []
    bw_list = []

    # Iterate over each file
    for file in files:
        print ("processing {}".format(file))
        file_byte_list = []
        file_bw_list = []

        with open(file, 'r') as f:
            # Read the lines of the file
            lines = f.readlines()
            start_extracting = False

            for line in lines:
                # Start extracting after the header line
                if "#        (B)" in line:
                    start_extracting = True
                    continue
                # Stop at the next comment line after data started
                if start_extracting and line.strip().startswith('#'):
                    break
                if not start_extracting:
                    continue
                # Split the line into columns
                columns = line.split()
                try:
                    file_byte_list.append(int(columns[0]))
                    file_bw_list.append(float(columns[11]))
                except (ValueError, IndexError):
                    print(f"Skipping line due to error: {line}")

        byte_list.append(file_byte_list)
        bw_list.append(file_bw_list)


    # Plot the data
    plt.figure(figsize=(12, 8))
    for i in range(len(files)):
        plt.plot(byte_list[i], bw_list[i], marker='o', label=files[i])
        #plt.plot(byte_list[i], bw_list[i], marker='o', markersize=3, linewidth=0.7, label=files[i])
    plt.xlabel('Message Size (bytes)')
    plt.ylabel('Bandwidth (GBps)')
    #plt.ylim(0, 100)
    plt.xscale('log', base=2)
    if byte_list:
        plt.xticks(byte_list[0], byte_list[0], fontsize=8, rotation=45)
    plt.title(f'NCCL {benchmark_name} InPlace BusBW with Different Message Size')
    plt.grid(True)
    plt.xticks(rotation=45)
    plt.legend()

    # Save the plot to a PDF file
    print(f"{output_name}.pdf")
    plt.savefig(f"{output_name}.pdf")


def print_help():
    help_message = """
    Usage: plot-bw-qp-scaling.py <file_pattern> <output_name>
    Arguments:
    <file_pattern> : The pattern to match log files (e.g., "write-bw--*.log", double quotes required)
    <output_name>  : The name of the output PDF file (e.g., write-bw)
    """
    print(help_message)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print_help()
    else:
        file_pattern = sys.argv[1]
        output_name = sys.argv[2]
        benchmark_name = sys.argv[3]
        print ("file pattern {}, output_name {}, benchmark {}".format(file_pattern, output_name, benchmark_name))
        plot_bandwidth(file_pattern, output_name, benchmark_name)

