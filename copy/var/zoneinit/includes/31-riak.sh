BUFFER_POOL_SIZE=$((${RAM_IN_BYTES}/2))
LOG_BUFFER_SIZE=8388608
LOG_FILE_SIZE=134217728

log "determining Riak secret cookie"

# First look for the metadata riak_secret key, if set in the request.
# If not, use special character free password.
# Worst case, use something hard-coded.

RIAK_SECRET=$(mdata-get riak_secret 2>/dev/null) ||\
  RIAK_SECRET=$(od -An -N8 -x /dev/random | head -1 | tr -d ' ') ||\
  RIAK_SECRET=$(echo -n "riak_${ZONENAME}" | /usr/bin/digest -a md5)

log "putting real data into Riak config files"

/opt/local/bin/gsed -i""                            \
  -e "s/##PRIVATE_IP##/${PRIVATE_IP}/"    \
  -e "s/##BUFFER_POOL_SIZE##/${BUFFER_POOL_SIZE}/" \
  -e "s/##LOG_BUFFER_SIZE##/${LOG_BUFFER_SIZE}/"   \
  -e "s/##LOG_FILE_SIZE##/${LOG_FILE_SIZE}/"       \
  -e "s/##RIAK_SECRET##/${RIAK_SECRET}/"           \
  /opt/local/etc/riak/{app.config,vm.args}

log "writing the Erlang cookie file"

echo "${RIAK_SECRET}" > /var/db/riak/.erlang.cookie
chown riak:riak /var/db/riak/.erlang.cookie
chmod 400 /var/db/riak/.erlang.cookie

log "starting Riak"

svcadm enable epmd
svcadm enable riak
