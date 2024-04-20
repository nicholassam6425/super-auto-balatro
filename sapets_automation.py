import csv
with open("sapets - consumables.csv", newline='') as csvfile:
    with open("c_ids_output.txt", "w") as outfile:
        csvreader = csv.reader(csvfile, delimiter=",")
        numline = 0
        for row in csvreader:
            if numline >= 1:
                temp = row[0].lower()
                temp = temp.replace(" ", "_")
                outfile.write(f"\"c_{(temp)}\", ")
            if numline % 6 == 0:
                outfile.write("\n")
            numline += 1