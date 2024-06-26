import json
import csv
import geopandas as gpd
from pyproj import Transformer
from shapely.geometry import Point
import random

# List of paths to your JSON files
json_file_paths = [
    r'C:\Users\noaom\Python Tryout Laren\Laren 1.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 2.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 3.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 4.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 5.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 6.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 7.json',
    r'C:\Users\noaom\Python Tryout Laren\Laren 8.json',

]

# Initialize empty lists to store transformed data
all_geographical_extent_data_2d = []

# Load and process each JSON file
for json_file_path in json_file_paths:
    with open(json_file_path, 'r') as file:
        data = json.load(file)

    # Extract x_max and y_max coordinates from "geographicalExtent" data for each city object
    for key, value in data['CityObjects'].items():
        geographical_extent = value.get('geographicalExtent')
        if geographical_extent is not None and len(geographical_extent) == 6:
            _, _, _, x_max, y_max, _ = geographical_extent
            all_geographical_extent_data_2d.append([x_max, y_max])

# If the total number of items is less than 5255, repeat randomly selected items until it reaches 5642
while len(all_geographical_extent_data_2d) < 5255:
    random_item = random.choice(all_geographical_extent_data_2d)
    all_geographical_extent_data_2d.append(random_item)

# Shuffle the list of geographical extent data
random.shuffle(all_geographical_extent_data_2d)

# Select the first 5642 items from the shuffled list
selected_coordinates = all_geographical_extent_data_2d[:5255]

# Define the original CRS (RD New) and the target CRS (WGS84)
original_crs = 'EPSG:28992'
target_crs = 'EPSG:4326'  # WGS84

# Initialize the transformer
transformer = Transformer.from_crs(original_crs, target_crs)

# Transform the coordinates to WGS84
all_coordinates_wgs84 = [transformer.transform(x, y) for x, y in selected_coordinates]

# Define the CSV file path to save the transformed data
csv_file_path = r'C:\Users\noaom\Python Tryout Laren\combined_household_coordinates.csv'

# Write the WGS84 geographical extent data to a CSV file
with open(csv_file_path, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    # Write the header row
    writer.writerow(['longitude', 'latitude'])
    # Write the WGS84 geographical extent data
    writer.writerows(all_coordinates_wgs84)

print("Geographical extent data has been transformed to WGS84 and saved to CSV:", csv_file_path)

# Create a GeoDataFrame from the transformed coordinates
geometry = [Point(lon, lat) for lon, lat in all_coordinates_wgs84]
gdf = gpd.GeoDataFrame(geometry=geometry, columns=['geometry'], crs=target_crs)

# Define the shapefile path to save the transformed data
shapefile_path = r'C:\Users\noaom\Python Tryout Laren\combined_household_coordinates.shp'

# Save the GeoDataFrame as a shapefile
gdf.to_file(shapefile_path)

print("Geographical extent data has been transformed to WGS84 and saved to Shapefile:", shapefile_path)
