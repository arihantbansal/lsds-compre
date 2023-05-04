#!/bin/sh

set -o errexit

cargo build

kill() {
    if [ "$(uname)" = "Darwin" ]; then
        SERVICE='raft-key-value'
        if pgrep -xq -- "${SERVICE}"; then
            pkill -f "${SERVICE}"
        fi
    else
        set +e # killall will error if finds no process to kill
        killall raft-key-value
        set -e
    fi
}

nd1=192.168.109.247:21003
nd2=192.168.109.131:21003
nd3=192.168.109.5:21003

rpc() {
    local uri=$1
    local body="$2"

    echo '---'" rpc(:$uri, $body)"

    {
        if [ ".$body" = "." ]; then
            time curl --silent "$uri"
        else
            time curl --silent "$uri" -H "Content-Type: application/json" -d "$body"
        fi
    } | {
        if type jq > /dev/null 2>&1; then
            jq
        else
            cat
        fi
    }

    echo
    echo
}


export RUST_LOG=trace

echo "Killing all running p2p-messages"

kill

sleep 1

echo "Start 3 uninitialized raft-key-value servers..."

init_time=$(date +%s)

nohup ./target/debug/raft-key-value  --id 1 --http-addr $nd1 --initialized-at $init_time  --timeout 3 > n1.log &
sleep 1
echo "Server 1 started"

echo "Initialize server 1 as a single-node cluster"
sleep 2
echo
rpc $nd1/init '{}'

echo "Server 1 is a leader now"

sleep 2

echo "Get metrics from the leader"
sleep 2
echo
rpc $nd1/metrics
sleep 1

sleep 2
echo "Get metrics from the leader, after adding 2 learners"
sleep 2
echo
rpc $nd1/metrics
sleep 1

echo "Changing membership from [1] to 3 nodes cluster: [1, 2, 3]"
echo
rpc $nd1/change-membership '[1, 2, 3]'
sleep 1
echo 'Membership changed to [1, 2, 3]'
sleep 1

echo "Get metrics from the leader again"
sleep 1
echo
rpc $nd1/metrics
sleep 1

echo "Write data on leader"
sleep 1
echo
rpc $nd1/write '{"Set":{"key":"foo","value":"bar"}}'
sleep 1
echo "Data written"
sleep 1

echo "Read on every node, including the leader"
sleep 1
echo "Read from node 1"
echo
rpc $nd1/read  '"foo"'

echo "Changing membership from [1,2,3] to [3]"
echo
rpc $nd1/change-membership '[3]'
sleep 1
echo 'Membership changed to [3]'
sleep 1

echo "Write foo=zoo on node-3"
sleep 1
echo
rpc $nd3/write '{"Set":{"key":"foo","value":"zoo"}}'
sleep 1
echo "Data written"
sleep 1

echo "Read foo=zoo from node-3"
sleep 1
echo "Read from node 3"
echo
rpc $nd3/read  '"foo"'
echo


echo "Killing all nodes..."
kill
