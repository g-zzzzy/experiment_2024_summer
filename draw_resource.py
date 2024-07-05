import pandas as pd
import matplotlib.pyplot as plt
import sys
import os

def plot_from_csv(csv_file):
    df = pd.read_csv(csv_file, skiprows=5)
    df['time'] = pd.to_datetime(df['time'], format='%b-%d %H:%M:%S')

    # 计算时间的偏移量（以秒为单位）
    df['time'] = (df['time'] - df['time'].iloc[0]).dt.total_seconds()
    # 处理数据
    cpu_usage = df[['usr', 'sys', 'idl']]
    memory_usage = df[['used', 'free', 'cach', 'avai']]
    #计算吞吐
    df['recv_t'] = ((df['recv'] * 8) / 1024) / 1024
    df['send_t'] = ((df['send'] * 8) / 1024) / 1024

    # 绘制 CPU 使用率
    plt.plot(df['time'], (cpu_usage['usr'] + cpu_usage['sys']) / df['recv_t'], label='CPU Usage/Gbps', color='blue', linestyle='-', linewidth=1.5)
    #plt.plot(df['time'], (cpu_usage['usr'] + cpu_usage['sys']) / df['send_t'], label='send CPU Usage/Gbps', color='red', linestyle='-', linewidth=1.5)

    # 绘制内存使用量
    plt.plot(df['time'], (memory_usage['used'] / (1024**3)) / df['recv_t'], label='Memory Used (GB/Gbps)', color='green', linestyle='--', linewidth=1.5)
    #plt.plot(df['time'], (memory_usage['used'] / (1024**3)) / df['send_t'], label='send Memory Used (GB/Gbps)', color='yellow', linestyle='--', linewidth=1.5)

    # 绘制图表
    plt.xlabel('Time (seconds)')
    plt.ylabel('Percentage / GB')
    plt.title('CPU Usage and Memory Usage Over Time')
    plt.legend()
    base_name = os.path.splitext(os.path.basename(csv_file))[0]
    png_file = f'{base_name}.png'
    plt.savefig(png_file)
    plt.show()
    

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <csv_file>")
        sys.exit(1)

    csv_file = sys.argv[1]
    plot_from_csv(csv_file)
