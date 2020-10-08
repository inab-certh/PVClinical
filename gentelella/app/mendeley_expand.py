from mendeley import Mendeley
from mendeley.exception import MendeleyException, MendeleyApiException
from mendeley.session import MendeleySession
from oauthlib.oauth2 import TokenExpiredError

# extending the MendeleySession class to do auto-token-refresh on 
# token expiration. Mendeley access tokens expire after 1 hour.
class AutoRefreshMendeleySession(MendeleySession):
    def __init__(self, mendeley, token, refresh_token):
        super(AutoRefreshMendeleySession, self).__init__(mendeley, token)
        # silly name to avoid namespace collision with oauth refresh_token() method
        self.the_refresh_token = refresh_token
        self.client_secret = mendeley.client_secret

    def request(self, method, url, data=None, headers=None, **kwargs):
        try:
            # just try the MendeleySession request first
            return super(AutoRefreshMendeleySession, self).request(method, url, data, headers, **kwargs)
        except (MendeleyApiException, TokenExpiredError) as e:
            print ("Receiving " + type(e).__name__)
            # Check to see if we have an expired access token. This comes in two
            # forms: either a MendeleyApiException or OAuthlib's TokenExpiredError
            #
            # Mendeley's API uses MendeleyAPIException for everything so you have
            # to unpack it and inspect to see if it's a token expiration or not.
            # In event of an expired token it sends back a 401 with the JSON message
            # {"message": "Could not access resource because: Token has expired"}
            # and the Python SDK forms a MendeleyAPIException with this message
            # in e.message and 401 in e.status
            # OAuthlib will send a TokenExpiredError if you have a long-running
            # session that goes over an hour. MendeleyApiException occurs when 
            # you try to make a first request with an already expired token (such
            # as the one that's probably in your app's config file.)
            if ((type(e).__name__ is 'MendeleyApiException') and (e.status == 401) and ('Token has expired' in e.message)) or (type(e).__name__ is 'TokenExpiredError'):
                print ("Handling a token expiration of type " + type(e).__name__)
                self.refresh_token('https://api.mendeley.com/oauth/token', self.the_refresh_token, auth=(self.client_id, self.client_secret), redirect_uri="http://127.0.0.1:8000/")
                return super(AutoRefreshMendeleySession, self).request(method, url, data, headers, **kwargs)
            else:
                print ("Re-raising " + type(e).__name__)
                # pass on other mendeley exceptions
                raise



'''

except
            # page_id = str(page_id)
            # scenario_id = str(scenario_id)
            client_id = 8509
            redirect_uri = "http://127.0.0.1:8000/"
            client_secret = "4en8hOV7M8nz5Eca"
            mendeley = Mendeley(client_id, redirect_uri=redirect_uri)
            access_token = list(mend_cookies)[0].value



            auth = mendeley.start_authorization_code_flow()
            # auth = mendeley.start_implicit_grant_flow()
            # auth = mendeley.start_client_credentials_flow()

            login_url = auth.get_login_url()
            # state = urlparse(login_url).query.split("&")[4].split("=").pop()
            # auth_response = "http://127.0.0.1:8000/#access_token=" + access_token + "&state=" + state
            # session = auth.authenticate(auth_response)
            # mendeley.refresh(session)
            # mendeley = Mendeley(client_id, client_secret)
            # session = AutoRefreshMendeleySession(mendeley, {'access_token': access_token, 'token_type': "Bearer"},
            #                                      REFRESH_TOKEN)
            # login_url =  login_url.replace("code", "token")
            # redirect(login_url)
            # login_url = login_url + "&authType=SINGLE_SIGN_IN&prompt=login"
            # return render(request, 'app/index.html',
            #               {"scenario": scenario, 'records': records, 'pages': pages, 'page_id': page_id})
            # return redirect(login_url)
            
else

                    
'''