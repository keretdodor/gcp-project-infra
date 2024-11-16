#!/bin/bash

chmod 600 mongo_key.pem
ssh -o StrictHostKeyChecking=no -i mongo_key.pem -t keretdodorc@"$1" bash -c "
    mongosh --eval 'rs.initiate()'
    mongosh --eval 'db.adminCommand({ setDefaultRWConcern: 1, defaultWriteConcern: { w: \"majority\" } })'
    mongosh --eval 'rs.add(\"$2:27017\");'
    mongosh --eval 'cfg = rs.conf(); cfg.members[0].host = \"$1:27017\"; rs.reconfig(cfg);'
    mongosh --eval 'rs.addArb(\"$3:27017\");'
    
"
