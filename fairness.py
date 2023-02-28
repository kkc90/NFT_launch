import os
import math

base_dir = '/home/noms/launchNFT/NFT_launch'
file_name = 'analysis_dutch.txt'
path = os.path.join(base_dir, file_name)

file_opened = open(path)

# for line in file_opened.readlines():
#     print(line)

histogram = [0,0,0,0,0,0,0,0,0,0,0,0,0]

cnt = 0
for line in file_opened.readlines():
    if cnt == 0:
        cnt = cnt + 1
        continue
    balance = line.split()[2]
    numOfsuccess = line.split()[3]
        
    # print("Balance: " + balance + ", The number of NFTs minted: " + numOfsuccess)
    cnt = cnt + 1
    
    if numOfsuccess != 0:
        histogram[math.floor(float(balance))] = histogram[math.floor(float(balance))] + int(numOfsuccess)
        
# print(histogram)
for index, value in enumerate(histogram):
    # print(element[0]+"~"+(element[0]+0.99)+": " + element[1])
    print(f"[{index} ~ {index+1}), num={value}")