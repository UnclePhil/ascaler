#!/bin/bash
# external variables
LOOP=${LOOP:='yes'}
CPU_UPPER_LIMIT=${CPU_UPPER_LIMIT:=85}
CPU_LOWER_LIMIT=${CPU_LOWER_LIMIT:=25}
PROMETHEUS_URL=${PROMETHEUS_URL:=http://apps6.local:9090}
##wait time WITH units 3600s 60m 1h 
WAIT_TIME=${WAIT_TIME:=60s}

# internal variables

PROMETHEUS_API="api/v1/query?query="

## PKO acquire all service with the label "swarm.autoscaler=true"
## return the service name, the min replica, the max replica 
## ================================================================
get_svc_ascaler() {
    local services=$(docker service inspect $(docker service ls -q) | jq  '[.[] | select(.Spec.Labels["ascaler"]=="true")| [ .Spec.Name, .Spec.Labels["ascaler.minimum"], .Spec.Labels["ascaler.maximum"], .Spec.Mode.Replicated.Replicas] ] ')
    echo $services 
}

## PKO search last metrics for the requested service (param $1)
## return the last 5 min aggregation in %
## ================================================================
get_svc_metrics() {
  local SVC=$1
  local PQUERY=sum%28rate%28container_cpu_usage_seconds_total%7Bcontainer_label_com_docker_swarm_service_name%3D%22$SVC%22%7D%5B5m%5D%29%20%29%2A100
  local value=$(curl --silent "${PROMETHEUS_URL}/${PROMETHEUS_API}${PQUERY}" | jq -r '.data.result[0].value[1]')
  # at startup or if not present Prometheus send a null value
  # set value to zero to avoid a infinite scale up  
  if [ -z "$value" ]; then
    value=0
  fi
  echo $value 
}

## scale to new value
## param 1 : services
## param 2 : new repl value
scale() {
  docker service scale $1=$2 >>/dev/null
  echo "INFO:  $1 scaled to $2 replicas"
} 


check () {
  # get services 
  assvcs=$(get_svc_ascaler)
  echo "Service to survey"
  echo $assvcs
  items=$(echo "$assvcs" | jq -c -r '.[]')
  for item in ${items[@]}; do
      ## split data
      local  svc=$(echo "$item" | jq -c -r '.[0]')
      local  min=$(echo "$item" | jq -c -r '.[1]')
      local  max=$(echo "$item" | jq -c -r '.[2]')
      local repl=$(echo "$item" | jq -c -r '.[3]')
      echo check $svc

      ## set default replicas (min or max)
      ## if repl < min =>> set repl to min
      if [ $repl \< $min ]; then
        scale $svc $min 
      elif [ $repl \> $max ]; then
        scale $svc $max
      fi

      ## get metrics 
      metric=$(get_svc_metrics $svc)
      if [ $metric \< $CPU_LOWER_LIMIT ]; then
        newrepl=$(( repl-1 ))
        if [ "$newrepl" -ge "$min" ]; then
          scale $svc $newrepl
        fi
      elif [ $metric \> $CPU_UPPER_LIMIT ]; then
        newrepl=$(( repl+1 ))
        if [ "$newrepl" -le "$max" ]; then
          scale $svc $newrepl
        else
          echo "WARNING: $svc need more replica than authorized" 
        fi
      fi
  done
}

## Main loop
echo "****************************************************************************"
echo "**  ASCALER V1.00                                                         **"
echo "**  A Docker Swarm Simple Scaler                                          **"
echo "**                                                                        **"
echo "**  Base Idea : docker-swarm-autoscaler                                   **"
echo "**  Rewrite by Unclephil                                                  **"
echo "**  sources: https://github.com/UnclePhil/ascaler                         **"
echo "**                                                                        **"
echo "****************************************************************************"

check
while [[ $LOOP == 'yes' ]]; do
  echo "Waiting $WAIT_TIME"
  sleep $WAIT_TIME
  check
done
