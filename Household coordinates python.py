import json
import csv
import geopandas as gpd
from pyproj import Transformer
from shapely.geometry import Point

# Specify the path to your JSON file
json_file_path = r'C:\Users\noaom\PYTHON TRYOUTS\new.json'

# Load JSON data from the file into a Python dictionary
with open(json_file_path, 'r') as file:
    data = json.load(file)

# Extract x_max and y_max coordinates from "geographicalExtent" data for each city object
geographical_extent_data_2d = []

for key, value in data['CityObjects'].items():
    # Access the 'geographicalExtent' field within each object
    geographical_extent = value.get('geographicalExtent')
    if geographical_extent is not None and len(geographical_extent) == 6:
        # Extract x_max and y_max coordinates (ignoring z)
        _, _, _, x_max, y_max, _ = geographical_extent
        # Append the 2D geographical extent data to the list
        geographical_extent_data_2d.append([x_max, y_max])

# Define the original CRS (RD New) and the target CRS (WGS84)
original_crs = 'EPSG:28992'
target_crs = 'EPSG:4326'  # WGS84

# Initialize the transformer
transformer = Transformer.from_crs(original_crs, target_crs)

# Transform the coordinates to WGS84
household_coordinates = [transformer.transform(x, y) for x, y in geographical_extent_data_2d]

# Define the CSV file path to save the transformed data
csv_file_path_wgs84 = r'C:\Users\noaom\PYTHON TRYOUTS\household_coordinates.csv'

# Write the WGS84 geographical extent data to a CSV file
with open(csv_file_path_wgs84, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    # Write the header row
    writer.writerow(['longitude', 'latitude'])
    # Write the WGS84 geographical extent data
    writer.writerows(household_coordinates)

print("Geographical extent data has been transformed to WGS84 and saved to CSV:", csv_file_path_wgs84)

# Create a GeoDataFrame from the transformed coordinates
geometry = [Point(lon, lat) for lon, lat in household_coordinates]
gdf = gpd.GeoDataFrame(geometry=geometry, columns=['geometry'], crs=target_crs)

# Define the shapefile path to save the transformed data
shapefile_path_wgs84 = r'C:\Users\noaom\PYTHON TRYOUTS\household_coordinates.shp'

# Save the GeoDataFrame as a shapefile
gdf.to_file(shapefile_path_wgs84)

print("Geographical extent data has been transformed to WGS84 and saved to Shapefile:", shapefile_path_wgs84)
