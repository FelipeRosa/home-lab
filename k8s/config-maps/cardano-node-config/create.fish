kubectl create configmap cardano-node-config \
    --from-file=alonzo-genesis.json \
    --from-file=byron-genesis.json \
    --from-file=shelley-genesis.json \
    --from-file=config.json \
    --from-file=topology.json
