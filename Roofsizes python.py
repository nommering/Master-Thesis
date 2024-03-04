import json
import csv
import os

# Specify the path to your JSON file
json_file_path = r'C:\Users\noaom\PYTHON TRYOUTS\new.json'

# Load JSON data from the file into a Python dictionary
with open(json_file_path, 'r') as file:
    data = json.load(file)

# Extract "b3_opp_dak_schuin" values as an array
roofsizes = []

for key, value in data['CityObjects'].items():
    # Access the 'attributes' dictionary within each object
    attributes = value.get('attributes', {})
    
    # Extract the value of 'b3_opp_dak_schuin' and append it to the list
    b3_opp_dak_schuin = attributes.get('b3_opp_dak_schuin')
    if b3_opp_dak_schuin is not None:
        roofsizes.append(b3_opp_dak_schuin)

# Define the path for the CSV file
csv_file_path = os.path.join(os.path.dirname(json_file_path), 'roofsizes.csv')

# Write the roofsizes array to a CSV file
with open(csv_file_path, 'w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['roofsizes'])  # Write header
    writer.writerows(map(lambda x: [x], roofsizes))

print(f"CSV file saved at: {csv_file_path}")
