import pandas as pd
import numpy as np

input_file = r"D:/UserBehavior.csv"
output_file = r"D:/UserBehavior_sample.csv"

chunk_size = 500000
sample_list = []

# 加上 header=None，表示原文件没有表头
for chunk in pd.read_csv(input_file, chunksize=chunk_size, header=None):

    sample = chunk.sample(frac=0.001, random_state=42)
    sample_list.append(sample)

result = pd.concat(sample_list, ignore_index=True)

# 保存时不加表头（保持原格式）
result.to_csv(output_file, index=False, header=False)

print(f"共保存 {len(result)} 行")