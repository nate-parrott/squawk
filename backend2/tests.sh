
echo "Starting mongoDB silently"
mongod > /dev/null &
source venv/bin/activate
echo "Starting the backend locally"
foreman start &
sleep 2s
echo "RUNNING TESTS"
python test.py
