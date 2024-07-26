#!/bin/bash

echo "STARTING DOCKER CONTAINER"
docker-compose up &
sleep 5
echo "STARTING ZROK"
zrok share public localhost:3000 &
sleep 15
echo "SENDING EMAIL"
cargo run --bin url
sleep 5
echo "THE END"
