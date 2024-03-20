# OD-poster-ESSA-Glasgow-2023

This is the repository for the poster I made for the ESSA conference in Glasgow 2023. My aim with this was to get a first grip on inverse modelling and share what I have learned with the community. I'm happy to share the poster upon request via [lschubotz@tudelft.nl].

## How to Use

Provided in this repository is the code for three models. The voter model has two files, "Voting.nlogo" and "Voting_w_clusters.nlogo". These can be run independently.
All files with the prefix "bc_" belong to the bounded confidence model. bc_6_3.nlogo is the netlogo file converted to Netlogo version 6.3. bc_generate_data.py generates some data that bc_main.py can match which is the main file for this simulation and fitting run, but any curve can be matched, merely the file names need to be exchanged.
The same structure applies for the culture dissemination model with the prefix "cd_".
An effort has been made to use self-explanatory variable names and file names. If any questions or unclarities remain or errors are encountered, the author is grateful for a brief message.

Install all necessary dependencies through the file requirements.txt, e.g., using `pip install -r requirements.txt`.

## Licensing Information

Since the Python code in this essential part of the project, the repository's license is Apache 2.0. Please note the specifications in the following licensing information!

### Data
The data used for this project is licensed under the Creative Commons Attribution ShareAlike 4.0 License (CC BY-SA 4.0). It is available in a 4 TU Repository via [https://doi.org/10.4121/6ca3d747-ac81-4571-be33-af1948b0dfba].

### Code
I wrote the Python code in this repository and license it under the Apache License 2.0.

The Netlogo code in this project is based on the models listed below. Special licensing may apply.

### Models
The models in this repository are licensed as follows:

#### Voting Model
- *Source*: NetLogo Models Community Library
- *Copyright*: 1998 Uri Wilensky
- *License*: CC BY-NC-SA 3.0
- *Contact*: uri@northwestern.edu
- *URL*: [https://ccl.northwestern.edu/netlogo/models/Voting](https://ccl.northwestern.edu/netlogo/models/Voting)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License. To view a copy of this license, visit CC BY-NC-SA 3.0.

#### Continuous Opinion Dynamics under Bounded Confidence
- *Source*: NetLogo Models Community Library
- *Copyright*: 2012 Jan Lorenz
- *License*: CC BY-SA 3.0
- *Contact*: post@janlo.de
- *URL*: [https://ccl.northwestern.edu/netlogo/models/Voting](https://ccl.northwestern.edu/netlogo/models/community/bc)

This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. To view a copy of this license, visit CC BY-SA 3.0.

#### Axelrod’s Model of Cultural Dissemination
- *Source*: NetLogo Models Community Library
- *Copyright*: 2013 Arezky H. Rodríguez
- *License*: not specified, but with kind permission from the author
- *Contact*: arezky@gmail.com
- *URL*: [https://ccl.northwestern.edu/netlogo/models/community/Axelrod_Cultural_Dissemination](https://ccl.northwestern.edu/netlogo/models/community/Axelrod_Cultural_Dissemination)

## Miscellaneous

### How to Cite

Please cite this work as
Schubotz, L.,  Chappin, E., Scholz, G. (2023). Cinderella's Slipper: Inverse Modelling of Energy Transition Votes in Opinion Dynamics. Presented at the Social Simulation Conference 2023 in Glasgow. URL: https://github.com/Miraculiciously/OD-poster-ESSA-Glasgow-2023/

### Errors

Using the file bc_6_3.nlogo, you might occasionally encounter a NetLogoException indicating an attempt to calculate the mean of an empty list. This is inherently a NetLogo model issue, as under standard conditions, the list being referenced shouldn't be empty. To my knowledge, this does not influence the code much. It might come from the fact that the downloaded model was wirtten for Netlogo 5.0 and I transitioned it to netlogo 6.3.0. Please be aware of this little "teething problem" when running the model.
