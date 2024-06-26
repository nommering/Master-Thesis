This repository has been created for the fulfillment of my Master Thesis. Provided in this repository is the code of a model applied to the data of the municipality of Vaals 
in the Netherlands. It includes also the original NetLogo model and the json and Python files used to generate data for this NetLogo model.
The model can be run using the *main* file.

### Code and Licensing
This project is based on code originally developed by Lukas Schubotz, published under the Apache 2.0 license. 
Some source files have been modified by Noa Ommering from February 2024 to July 2024. 

The model can be run using the *main* file. However, necessary data is required to run this file. Therefore, the *generate_data* file should be run before. 

The data for the *generate_data* file is retrieved from these CBS pages:
https://opendata.cbs.nl/#/CBS/nl/dataset/84518NED/table?ts=1710165208033 
https://opendata.cbs.nl/#/CBS/nl/dataset/85005NED/table 

The municipality-specific data (e.g. roofsizes, geolocation) that is used in the NetLogo model is retrieved from: 
https://3dbag.nl/en/viewer 

Note that the *model* file makes use of PyNetlogo. PyNetlogo is a Python library that enables interaction and control of NetLogo simulations directly from Python. 
- *Authors*: Marc Jaxa-Rozen & Jan Kwakkel
- *Title*: PyNetLogo: Linking NetLogo with Python
- *doi*: 10.18564/jasss.3668
- *Citation*: Jaxa-Rozen, M., & Kwakkel, J. H. (2018). PyNetLogo: Linking NetLogo with Python. Journal of Artificial Societies and Social Simulation, 21(2). https://doi.org/10.18564/jasss.3668

#### Modified Files:
-*muelder_error* \
-*muelder_generate_data* \
-*muelder_main* \
-*muelder_model* \
-*optimise* \
-*muelder_plot_fit* \
-*muelder_validation_curve* 

#### Unchanged Files:
-*muelder_custom_cv* 

The Netlogo code in this project is based on the models listed below. Special licensing may apply. The code of this NetLogo model has also been modified by Noa Ommering from February 2024 to July 2024.

### Models
The models in this repository are licensed as follows:

#### One Theory - Many Formalisations
- *Source*: CoMSES Network
- *Authors*: Hannah Muelder & Tatiana Filatova
- *Title*: ABM Household Decision Making on Solar Energy using Theory of Planned Behaviour
- *doi*: 10.18564/jasss.3855
- *Citation*: Hannah Muelder, Tatiana Filatova (2019, May 21). “ABM Household Decision Making on Solar Energy using Theory of Planned Behaviour” (Version 1.0.0). CoMSES Computational Model Library. Retrieved from: https://www.comses.net/codebases/89a72b47-849e-4f1e-8e4d-c887f88388b9/releases/1.0.0/

