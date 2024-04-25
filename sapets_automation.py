import csv
import os
import shutil
with open("sapets - units.csv", newline='') as csvfile:
    with open("c_ids_output.txt", "w") as outfile:
        '''csvreader = csv.reader(csvfile, delimiter=",")
        numline = 0
        for row in csvreader:
            if numline >= 1:
                temp = row[0].lower()
                temp = temp.replace(" ", "_")
                outfile.write(f"\"j_{(temp)}_arachnei\", ")
            if numline % 6 == 0:
                outfile.write("\n")
            numline += 1
        '''
        
        csvreader = csv.reader(csvfile, delimiter=",")
        src1x = os.path.join("assets/textures/1x/j_ant_arachnei.png")
        src2x = os.path.join("assets/textures/2x/j_ant_arachnei.png")
        numline = 0
        for row in csvreader:
            if numline >= 342:
                filename = row[0].lower().replace(" ", "_")
                dst1x = os.path.join(f"assets/textures/1x/j_{filename}_arachnei.png")
                dst2x = os.path.join(f"assets/textures/2x/j_{filename}_arachnei.png")
                shutil.copy(src1x, dst1x)
                shutil.copy(src2x, dst2x)
            numline += 1
        