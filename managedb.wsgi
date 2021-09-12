import sys

sys.path.insert(0, '/var/www/managedb')
logging.basicConfig(filename='/var/log/managedb.log', level=logging.INFO)
from managedb import app as application

