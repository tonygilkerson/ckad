# Practice Questions

## Setup

### alias

Create a few aliases that will be used in every question

```sh
# Edit
~/.bashrc

# Add the following
alias cc=clear
alias ll='ls -ltr'

alias k=kubectl
alias ns='kubectl config set-context --current --namespace'
alias ctx='kubectl config use-context'

DEVTODO add an alias to display the current context and namespace

. .~/bashrc

```

optional

```bash
vim ~/myps1.sh

#!/bin/bash
myps1() {

  cluster="$(kubectl config current-context)"
  # The following assume a singel context exists
  ns=$(kubectl config view | yq e '.contexts[0].context.namespace' -)

  echo "($cluster:$ns)  \w$ "

}

# make executable
chmod +x myps1.sh
. ~/myps1.sh

export PS1="$(myps1)"
```

### vim

Toggling line numbers can be useful when finding syntax errors based on line but can be bad when wanting to mark&copy with mouse.

- `:set number` - show line numbers
- `:set nonumber` - don't show line numbers
- `:22` - jump to a line number

  >The above settings will already be configured in your real exam environment in ~/.vimrc. But it can never hurt to be able to type these down

vim ~/.vimrc
Now enter (in insert-mode activated with i) the following lines:

```sh
vim ~/.vimrc

# Insert the following lines:
set expandtab
set tabstop=2
set shiftwidth=2
```

- expandtab - use spaces for tab
- tabstop - amount of spaces used for tab
- shiftwidth - amount of spaces used during indentation

## Questions

### Create a namespace called `mynamespace` and a pod with image `nginx` called `mynginx` on this namespace

Answer:

```bash
k create ns mynamespace
k run mynginx --image=nginx -n mynamespace
```

### Create a manifest file called `pod.yaml` for a pod with image `nginx` called `nginx` in the namespace `mynamespace` then create the pod in the cluster.

Answer:

```bash
# Generate manifest
k run mynginx --image=nginx --dry-run=client -n mynamespace -oyaml > pod.yaml

# Apply
k apply -f pod.yaml
```

### Run an imperative command that will create a pod using the `busybox` image and runs the command `env` so that the output is saved in a file call `myout.txt`. After the commands runs the pod should automatically be removed.

Answer:

```sh
# Review the examples
k run -h | grep Examples: -A 28

# Run
k run -it --rm busybox --image=busybox --restart=Never --command -- env > myout.txt

# Verify
$ cat myout.txt
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM=xterm
HOSTNAME=busybox
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
HOME=/root
pod "busybox" deleted

# The --rm flag should automatically remove the pod
$ k get pods
No resources found in default namespace.
```

### Create a pod from a manifest file called `pod.yaml`. The pod should use the `busybox` image and run the command `env`.  Fetch the command output and save it to a file called `myout.txt`

Answer:

```sh
# Review usage
k run -h

# Generate manifest
k run mypod --image=busybox --dry-run=client --restart=Never -oyaml  --command -- env > pod.yaml

# Apply
k apply -f pod.yaml

# Verify
$ k get po
NAME    READY   STATUS      RESTARTS   AGE
mypod   0/1     Completed   0          16s

# Get logs save to file
k logs po/mypod > myout.txt

# Verify
$ cat myout.txt 
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=mypod
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
HOME=/root

```

### Create the yaml for a new namespace called `myns` without creating it

```sh
k create ns myns --dry-run=client -oyaml 
```

### Create the YAML for a new `ResourceQuota` called `myrq` with hard limits of 1 CPU, 1G memory and 2 pods without creating it.

Answer:

```sh
# Review examples
k create quota myquota --dry-run=client -oyaml -h | grep Examples:  -A5

# Generate manifests
k create quota myquota --dry-run=client --hard=cpu=1,memory=1G,pods=2 -oyaml > myquota.yaml

# Verify
$ cat myquota.yaml 
apiVersion: v1
kind: ResourceQuota
metadata:
  creationTimestamp: null
  name: myquota
spec:
  hard:
    cpu: "1"
    memory: 1G
    pods: "2"
status: {}
```

### Get pods on all namespaces

Answer:

```sh
k get po -A
```

### Create a pod with image `nginx` called `mynginx` and expose traffic on port `80`

Answer:

```sh
# Review usage
k run -h

# Generate manifest
k run mynginx --image=nginx --port=80 --dry-run=client -oyaml > mynginx.yaml

# Review
$ cat mynginx.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: mynginx
  name: mynginx
spec:
  containers:
  - image: nginx
    name: mynginx
    ports:
    - containerPort: 80
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Apply
k apply -f mynginx.yaml
```

### Change the `mynginx` pod's image to `nginx:1.7.1`. Observe that the container will be restarted as soon as the image gets pulled.

Answer:

```sh
# Edit pod in the cluster
k edit po/mynginx 

# Or edit pod manifest and apply
vim mynginx.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: mynginx
  name: mynginx
spec:
  containers:
  - image: nginx:1.7.1 # edit this line
    name: mynginx
    ports:
    - containerPort: 80
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Apply
k apply -f mynginx.yaml 

# Or use set
k set image po/mynginx mynginx=nginx:1.7.1

# In this case it took longe to formate the set command
# and get the name of the container than just editing in place
# There are some case where set might be faster see the examples
k set image -h | grep Examples: -A 12

# Watch the pod
k get po/mynginx -w
```

### Question 8.3

### Get `mynginx` pod's IP address and use a temp `busybox` image to wget its `/` endpoint.

Answer:

```sh
# Display the pod IP
k get po -owide

# Launch a utility pod
k run mybusybox --image=busybox --rm -it --command -- /bin/sh
/ # wget http://192.168.1.3/
Connecting to 192.168.1.3 (192.168.1.3:80)
saving to 'index.html'
index.html           100% |*********************************************|   612  0:00:00 ETA
'index.html' saved
```

### Question 8.4

Get the `mynginx` pod's manifest from the cluster and save it in a file called `mypod.yaml`

Answer:

```sh
k get po/mynginx -oyaml > mypod.yaml
```

### Question 8.5

Get information about the `mynginx` pod, including details about potential issues (e.g. pod hasn't started)

Answer:

```sh
k describe po/mynginx
```

### Question 8.6

Get current logs for the `mynginx` pod. Sho how if the pod crashed and restarted you could get logs about the previous instance.

Answer:

```sh
k logs po/mynginx 
k logs po/mynginx -p
```

### Question 8.7

Open an interactive shell in the `mynginx` pod.

Answer:

```sh
# Review usage
k exec -h

# Open interactive shell 
k exec -it pod/mynginx -- /bin/sh
```

### Question 9

Create a pod with image `busybox` that echoes 'hello world' and then exits

Answer:

```sh
# Review the examples
k run -h | grep Examples: -A 27

# Generate manifests and apply
k run mybox --image=busybox --dry-run=client -oyaml --command=true --restart=Never -- /bin/sh -c 'echo hello world' > mybox.yaml
k apply -f mybox.yaml

# Get logs
$ k logs po/mybox 
hello world

# Verify, should be 0/1 ready and status Completed
$ k get po
NAME    READY   STATUS      RESTARTS   AGE
mybox   0/1     Completed   0          3m15s
```

### Question 10

Create a pod with image `busybox` that echoes 'hello world' to the interactive terminal and then exits, but this time have the pod deleted automatically

Answer:

```sh
# Review help, I remember something about "--rm" so start there
$ k run -h | grep "\-\-rm" -A 2
    --rm=false:
        If true, delete the pod after it exits.  Only valid when attaching to the container, e.g. with '--attach' or with '-i/--stdin'.


# Run
k run mybox --image=busybox -it --rm --restart=Never --command=true -- /bin/sh -c 'echo hello world'
k get po # nowhere to be found :)
```

## Question 11

Create an nginx pod and set an env value as 'var1=val1'. Check the env value existence within the pod

Answer:

```sh
# Review usage
k run -h

# Generate manifest
k run mypod --image=nginx --env="var1=val1" --dry-run=client -oyaml > mypod.yaml

# Verify
cat mypod.yaml 

# Apply
k apply -f mypod.yaml 

# Shell into pod and echo env var
$ k exec -it mypod -- /bin/bash 
root@mypod:/# echo $var1
val1
```

### Question 12

Create a Pod with two containers, both with image `busybox` and command `echo hello; sleep 3600`. Connect to the second container and run 'ls'

Answer:

```sh
# Review usage
k run -h

# Generate manifests
k run my2cpod --image=busybox --dry-run=client --command=true -oyaml -- /bin/sh -c "echo hello; sleep 3600" > my2cpod.yaml

# Create second container by copying the first
vim my2cpod.yaml 

$ cat my2cpod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: my2cpod
  name: my2cpod
spec:
  containers:
  - command:
    - /bin/sh
    - -c
    - echo hello; sleep 3600
    image: busybox
    name: c1
    resources: {}
  - command:         # copied and renamed
    - /bin/sh
    - -c
    - echo hello; sleep 3600
    image: busybox
    name: c2 
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Apply
k apply -f my2cpod.yaml 

# Shell into second container
k exec -it my2cpod -c=c2 -- /bin/sh
/ # ls
bin    dev    etc    home   lib    lib64  proc   root   sys    tmp    usr    var
/ # 
```

### Question 12

Create a pod with an `nginx` container exposed on port `80`. Add a `busybox` init container which downloads a page using `wget -O /work-dir/index.html http://neverssl.com/online`. Make a volume of type `emptyDir` and mount it in both containers. For the `nginx` container, mount it on `/usr/share/nginx/html` and for the init container, mount it on `/work-dir`. When done, get the IP of the created pod and create a `busybox` pod and run `wget -O- <IP>`

Answer:

```sh
k run mywww --image=nginx --port=80 --dry-run=client -oyaml > mywww.yaml

# Search kubernetes.io/docs
# keywords: emptyDir and volumeMounts:
# Use help to edit file
vim mywww.yaml 
$ cat mywww.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: mywww
  name: mywww
spec:
  volumes:
  - name: myvolume
    emptyDir:
  initContainers:
  - name: myinit
    image: busybox
    volumeMounts:
    - mountPath: /work-dir
      name: myvolume
    command: ['sh', '-c', "wget -O /work-dir/index.html http://neverssl.com/online"]
  containers:
  - image: nginx
    name: mywww
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: myvolume
    ports:
    - containerPort: 80
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Get IP address
k get pods -owide

$ k get pods -owide
NAME    READY   STATUS    RESTARTS        AGE     IP            NODE     NOMINATED NODE   READINESS GATES
mywww   1/1     Running   0               8m1s    192.168.1.5   node01   <none>           <none>

# Create a work pod and sell into it
k run -it --image=busybox -- sh
/ # wget -O- 192.168.1.5
Connecting to 192.168.1.5 (192.168.1.5:80)
writing to stdout
...
```


DEVTODO left off here https://github.com/dgkanatsios/CKAD-exercises/blob/main/c.pod_design.md

### Question TBD

Create a namespace called `ggckad-s0` in your cluster.
Run the following pods in this namespace.

1. A pod called `pod-a` with a single container running the `kubegoldenguide/simple-http-server` image
2. A pod called `pod-b` that has one container running the `kubegoldenguide/alpine-spin:1.0.0` image, and one container running `nginx:1.7.9`

Write down the output of `kubectl get pods` for the `ggckad-s0` namespace.

Answer

DEVTODO - Redo this answer

There answer which I might want to update:

```bash
# Create namespace
k create namespace ggckad-s0
ns ggckad-s0

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

### Question

All operations in this question should be performed in the `ggckad-s2` namespace.

Create a ConfigMap called `app-config` that contains the following two entries:

- `connection_string` set to `localhost:4096`
- `external_url` set to `google.com`

Run a pod called `question-two-pod` with a single container running the `kubegoldenguide/alpine-spin:1.0.0` image, and expose these configuration settings as environment variables inside the container.

All operations in this question should be performed in the `ggckad-s2` namespace.
Create a ConfigMap called `app-config` that contains the following two entries:

Answer

```bash
# Create namespace
k create ns ggckad-s2
ns ggckad-s2

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

### Question

All operations in this question should be performed in the `ggckad-s2` namespace. Create a pod that has two containers. Both containers should run the `kubegoldenguide/alpine-spin:1.0.0` image. The first container should run as `user ID 1000`, and the second container with `user ID 2000`. Both containers should use file system `group ID 3000`.

Answer:

```bash
# Create namespace
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

### Question

All operations in this question should be performed in the `ggckad-s4` namespace. This question will require you to create a pod that runs the image `kubegoldenguide/question-thirteen`. This image is in the main Docker repository at [`hub.docker.com`](http://hub.docker.com/).

This image is a web server that has a health endpoint served at `/health`. The web server listens on port `8000`. (It runs Python’s SimpleHTTPServer.) It returns a 200 status code response when the application is healthy. The application typically takes `sixty seconds to start`.

Create a pod called `question-13-pod` to run this application, making sure to define `liveness` and `readiness` probes that use this health endpoint.

Answer:

```bash
# Create namespace
k create ns ggckad-s4
ns ggckad-g4

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

### Question

All operations in this question should be performed in the `ggckad-s5` namespace. Create a file called `question-5.yaml` that declares a deployment in the `ggckad-s5` namespace, with `six replicas` running the `nginx:1.7.9` image.

Each pod should have the label `app=revproxy`. The deployment should have the label `client=user`. Configure the deployment so that when the deployment is updated, **the existing pods are killed off before new pods are created** to replace them.

Answer:

```sh
# Create namespace
k create ns ggckad-s5
ns ggckad-s5

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

### Question

This is question x

Answer:

this the answer


