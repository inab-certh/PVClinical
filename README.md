## PVClinical Platform

The PVClinical project aims to build a web-based platform, built to support Active
Pharmacovigilance processes via the integration of several heterogeneous data sources.

### Prerequisites

- [x] **Redis Server** (used for caching)
- [x] **Postgresql Database Server** (used as the Django app's database)
- [x] **MongoDB Database Server** (used for the database containing openFDA data)
- [x] **Virtuoso Database Server** (used for the Knowledge Graph, concerning Drugbank and MedDRA graphs)
- [x] **Shiny Server** (deploying the Twitter workspace and openFDA applications)
- [x] **OpenFDA screenshots services** (screenshots API for openFDA workspace)
- [x] **Docker Server** (deploying the Broadsea Docker containers, for OHDSI tools and Atlas, used by OHDSI workspace)
- [x] **Apache Server** (hosting and serving the produced reports and analytics/results screenshots from various workspaces)
- [x] **Twitter Account and Credentials** ( to utilize the historical data Twitter APIv2, through Twitter workspace )
- [x] **Mendeley and Pubmed Accounts and Credentials** ( to utilize Mendeley and PubMed APIs through PubMed workspace )
- [x] [Optional] **Mail Server** (used by the auth procedures of the Django app)

#### Twitter Analytics shiny apps deployment
Twitter Analytics, are shiny apps that utilize Twitter API v2 endpoints, to offer analytics to users, using global, real-time and historical data that are provided by Twitter, for academic research.

[More info about Twitter Analytics shiny apps](twitter_analytics_apps/README.md)

#### ΟpenFDA shiny apps deployment
OpenFDA shiny apps are based on openfdashinyapps developed by Jonathan G Levine
( https://github.com/jonathanglevine/openfdashinyapps ).

The initial apps have been adapted to use locally stored data, that have been downloaded from openFDA official repositories ( https://open.fda.gov/data/downloads/ ).

Further modifications have been made to the apps, regarding both view aspects and functionality, in order to fulfill PVClinical needs.

[More info about the original apps](openFDA_apps/README.md)

#### OpenFDA screenshots services deployment
OpenFDA screenshots services is a special API, offering the capability to get screenshots of various openFDA-apps' views.

[More info about openFDA screenshots services](openfda-shots-services/README.md)

#### Deploying and integrating OHDSI tools into the PVClinical platform

Broadsea deploys the full OHDSI technology stack (R methods library & web tools), using cross-platform Docker container technology.

Broadsea Docker containers can be deployed, according to the instructions given at: https://github.com/OHDSI/Broadsea

To integrate the Broadsea docker containers into OHDSI workspace of PVClinical platform, apart from the proper variables ( the ones with OHDSI_ prefix ) that need to be set in the `settings.py` file of the project, before starting the containers, someone has to also substitute the default atlas directory in brodsea-webtools container, with the modified atlas directory provided on our repository, by mapping it to the respective directory in the container.

This can be done by adding a simple line to ***volumes*** subsection of ***broadsea-webtools*** section, in `docker-compose.yml` file.

The line should be something similar to: `- ./atlas:/usr/local/tomcat/webapps/atlas:ro`

#### Running PVClinical platform

##### Steps
[Optional] [Set up a virtualenv and activate](http://python-guide-pt-br.readthedocs.io/en/latest/dev/virtualenvs/)

##### Get the code
    git clone https://github.com/inab-certh/PVClinical.git
    cd PVClinical

##### Install requirements
    pip install -r requirements.txt


##### Adapt configuration settings
Finally, in order to run PVClinical platform, someone has to set the proper values for the variables found in `gentelella/gentelella/settings.py` file (a sample settings.example.py file is provided on our repository, rename it to settings.py). corresponding to the particular system configuration and setup.

##### Run the code
    cd gentelella
    python manage.py runserver

##### Behold!
Go to http://localhost:8000/

#### Deploying PVClinical on web server using WSGI or ASGI
On our repository we provide a sample WSGI file ( `gentelella/gentelella/wsgi.py` ), to deploy PVClinical platform on a web server (e.g. Apache). More information on WSGI and ASGI interfaces, and configurations, can be found in the following link:

[How to deploy Django](https://docs.djangoproject.com/en/4.0/howto/deployment/)

###### Based on
[Gentelella Admin Template](https://github.com/puikinsh/gentelella)

###### Contributors
[@bdimitriadis](https://github.com/bdimitriadis)
[@Dimstella](https://github.com/Dimstella)
[@ckakalou](https://github.com/ckakalou)

###### License
Licensed under the Apache License, Version 2.0 (the "License") modified with
Commons Clause Restriction -- see the LICENSE file for details
