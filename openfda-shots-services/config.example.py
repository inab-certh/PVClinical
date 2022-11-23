class Config(object):
    DEBUG = False
    TESTING = False


class ProductionConfig(Config):
    USERS_PASS_DB = "<path/to/json/file>"
    MEDIA_DIR = "<path/to/media/dir>"
    SECRET_KEY = "<a_secret_key>"


class DevelopmentConfig(Config):
    DEBUG = True
    USERS_PASS_DB = "<path/to/json/file>"
    MEDIA_DIR = "<path/to/media/dir>"
    SECRET_KEY = "<a_secret_key>"


class TestingConfig(Config):
    TESTING = True
