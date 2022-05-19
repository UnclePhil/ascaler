#!/bin/bash
# external variables
LOOP=${LOOP:='yes'}
CPU UPPER_LIMIT=${CPU_UPPER_LIMIT:=85}
CPU_LOWER_LIMIT=${CPU_LOWER_LIMIT:=25}
PROMETHEUS_URL=${PROMETHEUS_URL:=http://apps6.local:9090}

# internal variables

PROMETHEUS_API="api/v1/query?query="

## PKO acquire all service with the label "swarm.autoscaler=true"
## return the service name, the min replica, the max replica 
## ================================================================
get_svc_autoscaler() {
    local services=$(docker service inspect $(docker service ls -q) | jq  '[.[] | select(.Spec.Labels["swarm.autoscaler"]=="true")| {name:.Spec.Name, min:.Spec.Labels["swarm.autoscaler.minimum"], max:.Spec.Labels["swarm.autoscaler.maximum"],repl:.Spec.Mode.Replicated.Replicas}] ')
    echo $services 
}

## PKO search last metrics for the requested service (param $1)
## return the last 5 min aggregation in %
## ================================================================
get_svc_metrics() {
  local SVC=$1
  local PQUERY=sum%28rate%28container_cpu_usage_seconds_total%7Bcontainer_label_com_docker_swarm_service_name%3D%22$SVC%22%7D%5B5m%5D%29%20%29%2A100
  local value=$(curl --silent "${PROMETHEUS_URL}/${PROMETHEUS_API}${PQUERY}" | jq '.data.result[0].value[1]')
  echo $value 
}

## scale to new value
## param 1 : services
## param 2 : new repl value
scale() {
  docker service scale $1=$2
  echo "Service $1 scaled to $2 replicas"
} 


check () {
    # get services 
    assvcs= $(get_svc_autoscaler)


    # loop in labeled services
    for assvc in assvcs ; do
      echo "test  $assvc "
      ## set default replicas (min or max)
      ## if repl < min =>> set repl to min

      ## if repl > max =>> set repl to max

      ## get metrics 
      metric = $(get_svc_metrics $asservice)
      ## if metric  > CPU_UPPER_LIMIT =>> scale +1

      ## if metric  < CPU_LOWER_LIMIT =>> scale -1
    done
}

## Main loop

check
while [[ $LOOP == 'yes' ]]; do
  echo "Waiting 60 seconds for the next test"
  sleep 60s
  check
done
