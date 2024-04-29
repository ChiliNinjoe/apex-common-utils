import requests
import time

from dotenv import load_dotenv
import os

class OAuth_Client:
    """
    A class to handle OAuth authentication.
    
    Usage example:
        oauth = OAuth(os.environ['TOKEN_URL'],
                    os.environ['CLIENT_ID'],
                    os.environ['CLIENT_SECRET'])
        
        headers = {
            'Authorization': 'Bearer ' + oauth.get_access_token(),
            'Content-Type': 'application/json', 
        }
        response = requests.get(api_url, headers=headers)
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception("API request failed")
    """

    def __init__(self, token_url: str, client_id: str, client_secret: str) -> None:
        """
        Initializes the OAuth class with essential details.

        Parameters:
        - token_url (str): The URL to fetch the access token.
        - client_id (str): The client ID for OAuth.
        - client_secret (str): The client secret for OAuth.
        """
        self._token_url = token_url  # URL to obtain access token
        self._client_id = client_id  # Client ID for authentication
        self._client_secret = client_secret  # Client secret for authentication
        self.access_token = None  # Variable to store the access token
        self.expire_time = None  # Variable to store the token's expiration time
    
    def get_access_token(self) -> str:
        """
        Obtains the access token from the token URL.
        
        Returns the existing access token if it has not expired. 
        Otherwise, fetches a new token from the token URL.

        Returns:
        - str: The access token.

        Raises:
        - Exception: If failed to obtain access token from the token URL.
        """
        if self.access_token is not None and time.time() < self.expire_time:
            # Return existing token if it hasn't expired
            return self.access_token
        else:
            # Prepare data for request to obtain a new access token
            data = {
                'grant_type': 'client_credentials'
            }
            # Make a POST request to the token URL
            response = requests.post(self._token_url, data=data, auth=(self._client_id, self._client_secret))
            if response.status_code == 200:
                # Parse the access token and its expiry from response
                self.access_token = response.json().get('access_token')
                self.expire_time = time.time() + int(response.json().get('expires_in'))
                return self.access_token
            else:
                # Raise an exception if token couldn't be obtained
                raise Exception("Failed to obtain access token")


if __name__ == '__main__':
    load_dotenv()
    oauth = OAuth_Client(os.environ['TOKEN_URL'],
                os.environ['CLIENT_ID'],
                os.environ['CLIENT_SECRET'])
    print(oauth.get_access_token())
