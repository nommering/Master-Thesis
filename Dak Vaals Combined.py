import json
import csv
import os
import random

# List of paths to your JSON files
json_file_paths = [
    r'C:\Users\noaom\Python Tryout Vaals\Vaals 1.json',
    r'C:\Users\noaom\Python Tryout Vaals\Vaals 2.json',
    r'C:\Users\noaom\Python Tryout Vaals\Vaals 3.json',
    r'C:\Users\noaom\Python Tryout Vaals\Vaals 4.json',
]

# Initialize empty list to store all b3_opp_dak_schuin values
all_b3_opp_dak_schuin_values = []

# Load and process each JSON file
for json_file_path in json_file_paths:
    with open(json_file_path, 'r') as file:
        data = json.load(file)

    # Extract "b3_opp_dak_schuin" values as an array
    b3_opp_dak_schuin_values = []
    for key, value in data['CityObjects'].items():
        attributes = value.get('attributes', {})
        b3_opp_dak_schuin = attributes.get('b3_opp_dak_schuin')
        if b3_opp_dak_schuin is not None and b3_opp_dak_schuin != 0:  # Check if value is not None and not 0
            b3_opp_dak_schuin_values.append(b3_opp_dak_schuin)

    all_b3_opp_dak_schuin_values.extend(b3_opp_dak_schuin_values)

# If the total number of items is less than 5642, repeat randomly selected items until it reaches 5642
while len(all_b3_opp_dak_schuin_values) < 5642:
    random_value = random.choice(all_b3_opp_dak_schuin_values)
    all_b3_opp_dak_schuin_values.append(random_value)

# Shuffle the list of b3_opp_dak_schuin values
random.shuffle(all_b3_opp_dak_schuin_values)

# Select the first 5642 items from the shuffled list
selected_values = all_b3_opp_dak_schuin_values[:5642]

# Define the path for the CSV file
csv_file_path = os.path.join(os.path.dirname(json_file_paths[0]), 'combined_b3_opp_dak_schuin_values_vaals.csv')

# Write the combined b3_opp_dak_schuin_values to a CSV file
with open(csv_file_path, 'w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['b3_opp_dak_schuin_values'])  # Write header
    writer.writerows(map(lambda x: [x], selected_values))

print(f"CSV file saved at: {csv_file_path}")
