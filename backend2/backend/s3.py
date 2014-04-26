from boto.s3.connection import S3Connection
from boto.s3.key import Key
import uuid

def generate_unique_filename_with_ext(ext):
	return uuid.uuid1().hex+'.'+ext

def upload_file(filename, data):
	access_key = 'AKIAIYTZK6UBZOVD4DFA'
	secret_key = '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'
	conn = S3Connection(access_key, secret_key)
	bucket = conn.create_bucket('squawk2')
	k = Key(bucket)
	k.key = filename
	k.set_contents_from_string(data)
	return k.generate_url(expires_in=60*60*24*365, force_http=True) # 1 year
