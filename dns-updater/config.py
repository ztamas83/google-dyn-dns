import logging
import os
import os.path
import urllib.request
from dotenv import load_dotenv
from pathlib import Path
from google.cloud import secretmanager

API_KEY_NAME="apiKey"

class config():
    if os.path.isfile('.env'):
        env_path = Path('.') / '.env'
        load_dotenv(dotenv_path=env_path)

    def __init__(self):
        logging.info("Starting configuration.")
        
        url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
        req = urllib.request.Request(url)
        req.add_header("Metadata-Flavor", "Google")
        self.gcpProject = urllib.request.urlopen(req).read().decode()
        
        self.ttl = os.environ.get('ttl', 3600)

        #self.app = os.environ.get('app', '"app" variable has not been set.')
        # Fetch "app" key from Secret Manager
        secret_client = secretmanager.SecretManagerServiceClient()
        secret_name = f"projects/{self.gcpProject}/secrets/{API_KEY_NAME}/versions/latest"
        response = secret_client.access_secret_version(request={"name": secret_name})
        self.app = response.payload.data.decode("UTF-8")
        
        self.functionName = os.environ.get('FUNCTION_NAME', '')
        self.gcpRegion = os.environ.get('FUNCTION_REGION', '')
        self.gcpAuthKeyJsonFile = os.environ.get('authKeyJsonFile', '')
        self.gcpDnsZoneName = os.environ.get('dnsZoneName', '"dnsZoneName" variable has not been set.')
        self.gcpDnsDomain = os.environ.get('dnsDomain', '"dnsDomain" variable has not been set.')


cfg = config()
