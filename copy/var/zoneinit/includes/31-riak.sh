log "generating riak_secret"
# First look for the metadata riak_secret key, if set in the request.
# If not, generate our own.
RIAK_SECRET=${RIAK_SECRET:-$(mdata-get riak_secret 2>/dev/null) ||\
RIAK_SECRET=$(od -An -N8 -x /dev/random | head -1 | tr -d ' ');

log "putting real data into Riak config files"
gsed -i "s/127.0.0.1/${PRIVATE_IP}/g" /opt/local/etc/riak/app.config /opt/local/etc/riak/vm.args
gsed -i "s/^-setcookie riak/-setcookie ${RIAK_SECRET}/g" /opt/local/etc/riak/vm.args

log "writing the Erlang cookie file"
echo "${RIAK_SECRET}" > /var/db/riak/.erlang.cookie
chown riak:riak /var/db/riak/.erlang.cookie
chmod 400 /var/db/riak/.erlang.cookie

log "starting Riak"
svcadm enable epmd
svcadm enable riak
