# ascaler

## Current Release: 1.0.0

This project is a complete rewriting of the https://github.com/jcwimer/docker-swarm-autoscaler

Due to the intensive usage of _docker service inspect_ command.

On my cluster(s) the old project was a high cpu user (>15%) and i need to reduce that drastically.


## Usage
1. You can deploy prometheus, cadvisor, and ascaler by running `docker stack deploy -c swarm-ascaler-stack.yml ascaler` from the root of this repo.  
  * ascaler needs a placement contstraint to deploy to a manager. 
2. For services you want to autoscale you will need a deploy label `ascaler=true`. 

```
deploy:
  labels:
    - "ascaler=true"
```

This is best paired with resource constraints limits. This is also under the deploy key.

```
deploy:
  resources:
    reservations:
      cpus: '0.25'
      memory: 512M
    limits:
      cpus: '0.50'
```

## Configuration
| Setting | Value | Description |
| --- | --- | --- |
| `ascaler` | `true` | Required. This enables autoscaling for a service. Anything other than `true` will not enable it |
| `ascaler.minimum` | Integer | Optional. This is the minimum number of replicas wanted for a service. The autoscaler will not downscale below this number |
| `ascaler.maximum` | Integer | Optional. This is the maximum number of replicas wanted for a service. The autoscaler will not scale up past this number | 

## Test
You can deploy a test app with the following commands below. Helloworld is initially only 1 replica. The autoscaler will scale to the minimum 3 replicas.
1. `docker stack deploy -c swarm-ascaler-stack.yml ascaler`
2. `docker stack deploy -c helloworld.yml hello`