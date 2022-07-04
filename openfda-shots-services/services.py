import hashlib
import json
import re

from pathlib import Path
from flask import Flask
from flask import jsonify
from flask import make_response
from flask import request
from flask_httpauth import HTTPBasicAuth


app = Flask(__name__)
app.config.from_object('config.DevelopmentConfig')
auth = HTTPBasicAuth()

#logging.basicConfig(level=logging.DEBUG)

@auth.verify_password
def verify_pw(username, password):
    with open(app.config["USERS_PASS_DB"], "r") as fp:
        return json.load(fp).get(username) == hashlib.md5(password.encode()).hexdigest()


@app.route('/delete-media-file/<file_name>', methods=['DELETE'])
@auth.login_required
def delete_media_file(file_name):
    file_path = Path("{}{}".format(app.config["MEDIA_DIR"], file_name))

    try:
        file_path.unlink()
        resp_msg = "Successful deletion"
        resp_code = 200
    except FileNotFoundError:
        resp_code = 404
        resp_msg = "File not found"
    except:
        resp_code = 500
        resp_msg = "Internal server error"
    response = make_response(resp_msg, resp_code)
    response.headers['content-type'] = 'application/octet-stream'
    return response


@app.route('/list-media-files', methods=['GET'])
@auth.login_required
def list_media_files():
    """ List media files in media directory. If filetypes parameter is given,
    then keep only files with the specific extension(s)"""
    filetypes = request.args.getlist("filetypes")
    existing_media_files = map(lambda posix_file: posix_file.name, Path(app.config["MEDIA_DIR"]).iterdir())
    return jsonify(list(filter(lambda f: Path(f).suffix in filetypes,
                               existing_media_files)) if filetypes else list(existing_media_files))


@app.route('/delete-media-files', methods=['DELETE'])
@auth.login_required
def delete_media_files():
    """ Delete media files containing the specific hashes we are looking for in their filename
    """
    hashes = request.args.getlist("hashes")

    # Find all media files in media dir
    existing_media_files = map(lambda posix_file: posix_file.name, Path(app.config["MEDIA_DIR"]).iterdir())

    # Keep only the files with the hashes that we are looking for
    files_of_interest = filter(lambda fname: re.match("^[a-z0-9]*", fname).group() in hashes, existing_media_files)
    status_codes = []
    for file_name in files_of_interest:
        file_path = Path("{}{}".format(app.config["MEDIA_DIR"], file_name))

        try:
            file_path.unlink()
            # resp_msg = "Successful deletion"
            resp_code = 200
        except FileNotFoundError:
            resp_code = 404
            # resp_msg = "File not found"
        except:
            resp_code = 500
            # resp_msg = "Internal server error"
        finally:
            status_codes.append(resp_code)
    return jsonify({"status_codes": status_codes})


if __name__ == '__main__':
    app.run(debug = True)
    app.secret_key = app.config["SECRET_KEY"]

