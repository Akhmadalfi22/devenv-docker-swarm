#!/bin/bash

set -e

HOSTS=(db_mongo1 db_mongo2 db_mongo3)

for host in "${HOSTS[@]}"; do
  echo "Waiting for $host:27017 to be available..."
  while true; do
    if mongosh "mongodb://$host:27017" --eval "db.adminCommand('ping')" --quiet &>/dev/null; then
      echo "$host:27017 is up!"
      break
    else
      echo "Trying $host:27017..."
      sleep 10
    fi
  done
done

# Check if replica set is already initialized
if mongosh --host ${HOSTS[0]}:27017 -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --eval "rs.status()" --quiet; then
  echo "Replica set already initialized"
  exit 0
fi

# Initialize the replica set
mongosh --host ${HOSTS[0]}:27017 -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: '${HOSTS[0]}:27017', priority: 2 },
    { _id: 1, host: '${HOSTS[1]}:27017', priority: 1 },
    { _id: 2, host: '${HOSTS[2]}:27017', priority: 1 }
  ]
})
"

# Wait for primary to be elected
while true; do
  if mongosh --host ${HOSTS[0]}:27017 -u ${MONGO_INITDB_ROOT_USERNAME} -p ${MONGO_INITDB_ROOT_PASSWORD} --eval "db.hello().isWritablePrimary" --quiet 2>/dev/null | grep -q "true"; then
    echo "Primary elected successfully!"
    break
  else
    echo "Trying ${HOSTS[0]}:27017..."
    sleep 10
  fi
done