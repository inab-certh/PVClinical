## OpenFDA screenshots services

OpenFDA screenshots services is a Flask application, offering an API to users, to get screenshots of various openFDA-apps' views.

### Services deployment

- In order to run the OpenFDA screenshots services, you have to install the proper packages found in requirements.txt using pip3 (i.e. pip install -r requirements.txt)
and create a config.py file similar to config.example.py, with proper permissions.

- Additionally, depending on whether you want to deploy the services for production, development or testing purposes, you have to adapt the line `app.config.from_object('config.DevelopmentConfig')` in services.py file, accordingly, with the proper value (i.e. ProductionConfig, DevelopmentConfig, TestingConfig).

- Finally, you can use a wsgi file, similar to app.wsgi, adapted to your own settings, but that is optional, since it depends on the web server you are using for deployment (e.g. apache2 etc.), and your particular configuration in general.
