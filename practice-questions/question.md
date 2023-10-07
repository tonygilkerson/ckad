# Practice Questions

## Question 1

Create a namespace called `ggckad-s0` in your cluster.
Run the following pods in this namespace.

1. A pod called `pod-a` with a single container running the `kubegoldenguide/simple-http-server` image
2. A pod called `pod-b` that has one container running the `kubegoldenguide/alpine-spin:1.0.0` image, and one container running `nginx:1.7.9`

Write down the output of `kubectl get pods` for the `ggckad-s0` namespace.

### Answer 1

DEVTODO - Redo this answer

There answer which I might want to update:

```bash
# Setup
alias k=kubectl
alias ns="kubectl config set-context --current --namespace"
k create namespace ggckad-s0

# Generate pod manifests
kubectl run nginx --image=kubegoldenguide/simple-http-server --dry-run=client -o yaml > simple-http-server.yaml
kubectl run nginx --image=kubegoldenguide/alpine-spin:1.0.0 --dry-run=client -o yaml > alpine-spin.yaml
kubectl run nginx --image=nginx:1.7.9 --dry-run=client -o yaml > nginx.yaml

# Modify the generated files to give the following:
apiVersion: v1
kind: Pod
metadata:
  name: pod-a
  labels:
    role: myrole
spec:
  containers:
    - name: web
      image: kubegoldenguide/simple-http-server
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
  labels:
    role: myrole
spec:
  containers:
    - name: alpine-spin-container
      image: kubegoldenguide/alpine-spin:1.0.0
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
    - name: nginx-container
      image: nginx:1.7.9
      ports:
        - name: web
          containerPort: 80
          protocol: TCP

# Apply 
k apply -f pod-a.yaml --namespace ggckad-s0
k logs pod-a --namespace ggckad-s0
k apply -f pod-b.yaml --namespace ggckad-s0
k logs pod-b alpine-spin-container --namespace ggckad-s0
k logs pod-b nginx-container --namespace ggckad-s0
```

## Question 2

All operations in this question should be performed in the `ggckad-s2` namespace.

Create a ConfigMap called `app-config` that contains the following two entries:

- `connection_string` set to `localhost:4096`
- `external_url` set to `google.com`

Run a pod called `question-two-pod` with a single container running the `kubegoldenguide/alpine-spin:1.0.0` image, and expose these configuration settings as environment variables inside the container.

All operations in this question should be performed in the `ggckad-s2` namespace.
Create a ConfigMap called `app-config` that contains the following two entries:

### Answer 2

```bash
# Setup
alias k=kubectl
alias ns="kubectl config set-context --current --namespace"
k create ns ggckad-s2

# Use help to review command Usage example
k create cm --help

# Create manifest
k create cm app-config \
  --from-literal=connection_string=localhost:4096 \
  --from-literal=external_url=google.com \
  --dry-run=client -oyaml > app-config.yaml

# Review manifest and apply
cat app-config.yaml 
k apply -f app-config.yaml

# Review command Usage example
k run --help

# Create manifest
k run question-two-pod \
  --image=kubegoldenguide/alpine-spin:1.0.0 \
  --dry-run=client -oyaml > question-two-pod.yaml

# Research
#
# Figure out how to expose the configmap as environment variables
# 
# - open `http://kubernetes.io/docs`
# - search for configmap
# - click on "Configure a Pod to Use a ConfigMap"
# - look for `valueFrom` example to copy from
#
# or 
# Use explain to figure out how to expose the cm as env vars
k explain pod.spec.containers.env --recursive=true


# Edit file add the valueFrom section
vim question-two-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: question-two-pod
  name: question-two-pod
spec:
  containers:
  - image: kubegoldenguide/alpine-spin:1.0.0
    name: question-two-pod
    env:
    - name: CONNECTION_STRING
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: connection_string
    - name: EXTERNAL_URL 
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: external_url
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always

# Apply
k apply -f question-two-pod.yaml

# Verify
k exec -it  pod/question-two-pod /bin/sh

/ # echo $EXTERNAL_URL
google.com
/ # echo $CONNECTION_STRING
localhost:4096
/ #
```

## Question 3

All operations in this question should be performed in the `ggckad-s2` namespace. Create a pod that has two containers. Both containers should run the `kubegoldenguide/alpine-spin:1.0.0` image. The first container should run as `user ID 1000`, and the second container with `user ID 2000`. Both containers should use file system `group ID 3000`.

### Answer 3

```bash
# Setup
alias k=kubectl
alias ns="kubectl config set-context --current --namespace"

k create ns ggckad-s2
ns ggckad-s2

#
# Create base pod manifest
#
k run mypod --image=kubegoldenguide/alpine-spin:1.0.0 --dry-run=client -oyaml > mypod


# Research
#
# "user" is in the question so I start there
# Search pod spec for "user" because I did not remember "securityContext"
#
k explain pod.spec --recursive=yes | grep -i user

# Search kubernetes.io/docs for "securityContext" to find an example
# Also now that I know what it is called explain it to verify
k explain pod.spec.containers.securityContext

# Now I know enough to edit the base yaml
vim mypod.yaml

# Here is what it looks like when I am done
$ cat mypod.yaml 
apiVersion: v1
kind: Pod
metadata:
 creationTimestamp: null
 labels:
   run: mypod
 name: mypod
spec:
 containers:
 - image: kubegoldenguide/alpine-spin:1.0.0
   name: c1
   securityContext:
     runAsUser: 1000
     runAsGroup: 3000
 - image: kubegoldenguide/alpine-spin:1.0.0
   name: c2
   securityContext:
     runAsUser: 2000
     runAsGroup: 3000
   resources: {}
 dnsPolicy: ClusterFirst
 restartPolicy: Always
status: {}

# Apply
k apply -f mypod.yaml

# Verify
$ k exec -it pod/mypod -c=c1 -- /bin/sh  
/ $ id
uid=1000 gid=3000

$ k exec -it pod/mypod -c=c2 -- /bin/sh
/ $ id
uid=2000 gid=3000
```

## Question 4

All operations in this question should be performed in the `ggckad-s4` namespace. This question will require you to create a pod that runs the image `kubegoldenguide/question-thirteen`. This image is in the main Docker repository at [`hub.docker.com`](http://hub.docker.com/).

This image is a web server that has a health endpoint served at `/health`. The web server listens on port `8000`. (It runs Python’s SimpleHTTPServer.) It returns a 200 status code response when the application is healthy. The application typically takes `sixty seconds to start`.

Create a pod called `question-13-pod` to run this application, making sure to define `liveness` and `readiness` probes that use this health endpoint.

### Answer 4

```bash
# setups
alias k=kubectl
alias ns=kubectl config set-context --current --namespace
alias ns="kubectl config set-context --current --namespace"

k create ns ggckad-s4

# Generate pod manifests
k run --help
k run pod4 --image="kubegoldenguide/question-thirteen" --port=8000 --dry-run=client -oyaml > pod4.yaml

# Research
#
# search kubernetes.io/docs for "livenessProbe" 
# select "Configure Liveness, Readiness and Startup Probes"
# look for httpGet example to add the liveness and readiness probes below

vim pod4.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod4
  name: pod4
spec:
  containers:
  - image: kubegoldenguide/question-thirteen
    name: pod4
    readinessProbe:
      httpGet:
        path: /health
        port: 8000 
      initialDelaySeconds: 60
    livenessProbe:
      # need to add this to both readiness and liveness probes
      initialDelaySeconds: 60 
      httpGet:
        path: /health
        port: 8000
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always

# Apply
pod4.yaml

# Wait 60 seconds (or more)
# you are looking for 1/1 READY
$ k get pods
NAME   READY   STATUS    RESTARTS   AGE
pod4   1/1     Running   0          107s 
```

## Question 5

All operations in this question should be performed in the `ggckad-s5` namespace. Create a file called `question-5.yaml` that declares a deployment in the `ggckad-s5` namespace, with `six replicas` running the `nginx:1.7.9` image.

Each pod should have the label `app=revproxy`. The deployment should have the label `client=user`. Configure the deployment so that when the deployment is updated, **the existing pods are killed off before new pods are created** to replace them.

### Answer 5

```sh
# Setup
alias k=kubectl
alias ns="kubectl config set-context --current --namespace"

k create ns ggckad-s5

#
# Research
#

# Do this to find the deployment.spec.strategy is what I need
k explain deployment.spec --recursive=true | grep strategy -B 22 -A 3

# Do this to see that Recreate is what I want
controlplane $ k explain deployment.spec.strategy.type         
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: type <string>

DESCRIPTION:
    Type of deployment. Can be "Recreate" or "RollingUpdate". Default is
    RollingUpdate.
    
    Possible enum values:
     - `"Recreate"` Kill all existing pods before creating new ones.
     - `"RollingUpdate"` Replace the old ReplicaSets by new one using rolling
    update i.e gradually scale down the old ReplicaSets and scale up the new
    one.

# Generate manifest
k create deployment -h
k create deployment d5 --image=nginx:1.7.9 --dry-run=client -oyaml  > question-5.yaml

vim question-5.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    client: user
  name: d5
  namespace: ggckad-s5
spec:
  replicas: 6
  selector:
    matchLabels:
      app: revproxy
  strategy:
    type: Recreate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: revproxy
    spec:
      containers:
      - image: nginx:1.7.9
        name: nginx
        resources: {}
status: {}

# Apply
ns ggckad-s5
k apply -f question-5.yaml 

# Verify
# You should see six pod running
k get all
```

## Question x

This is quesion x

### Answer x

```sh
# Setup
```
## Question x

This is quesion x

### Answer x

```sh
# Setup
```
## Question x

This is quesion x

### Answer x

```sh
# Setup
```
## Question x

This is quesion x

### Answer x

```sh
# Setup
```
