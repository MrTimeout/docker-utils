#!/bin/bash

mongosh --username $MONGO_INITDB_ROOT_USERNAME --password $MONGO_INITDB_ROOT_PASSWORD --host mongo1 --port 27017 admin <<EOF
var cfg = {
    "_id": "dbrs",
    "version": 1,
    "members": [
        {
            "_id": 1,
            "host": "mongo1:27017",
            "priority": 3
        },
        {
            "_id": 2,
            "host": "mongo2:27017",
            "priority": 2
        },
        {
            "_id": 3,
            "host": "mongo3:27017",
            "priority": 1
        }
    ]
};
rs.initiate(cfg, { force: true });
rs.status();
EOF