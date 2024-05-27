import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')


# Load the data from the Excel file
excel_file = r'C:\Users\noaom\Python Tryout Vaals\SolarDataPerMunicipality.xlsx'
df = pd.read_excel(excel_file)

# Filter out the header rows
df = df.iloc[2:]

# Extract the years from the first row
years = df.columns[1:].tolist()

# Extract the municipalities and corresponding installation data
municipalities = df.iloc[:, 0].tolist()  # Extract municipality names
installation_data = df.iloc[:, 1:].values  # Extract installation data

# Create a dictionary to store the installation data for each municipality
municipality_installations = {}

# Iterate over each municipality and corresponding installation data
for municipality, installations in zip(municipalities, installation_data):
    municipality_installations[municipality] = installations.tolist()

# Convert the dictionary to a DataFrame
df_train = pd.DataFrame(municipality_installations)

# Transpose the DataFrame so that municipalities are rows and years are columns
df_train = df_train.transpose()

# Assign the years as column headers
df_train.columns = years

# Save the DataFrame to a CSV file
df_train.to_csv('solar_pv_training_data.csv')

# Plot the training data
plt.figure(figsize=(12, 6))
for municipality in df_train.index:
    plt.plot(years, df_train.loc[municipality], marker='o', label=municipality)
plt.title('Solar PV Installations Over Time by Municipality')
plt.xlabel('Year')
plt.ylabel('Installations')
plt.xticks(rotation=45)  # Rotate x-axis labels for better readability
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
plt.grid(True)
plt.tight_layout()
plt.show()
