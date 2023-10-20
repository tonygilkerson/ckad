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
alias getctx='kubectl config get-context'

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

```bash
k create ns mynamespace
k run mynginx --image=nginx -n mynamespace
```

### Create a manifest file called `pod.yaml` for a pod with image `nginx` called `nginx` in the namespace `mynamespace` then create the pod in the cluster.

```bash
# Generate manifest
k run mynginx --image=nginx --dry-run=client -n mynamespace -oyaml > pod.yaml

# Apply
k apply -f pod.yaml
```

### Run an imperative command that will create a pod using the `busybox` image and runs the command `env` so that the output is saved in a file call `myout.txt`. After the commands runs the pod should automatically be removed.

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

```sh
k get po -A
```

### Create a pod with image `nginx` called `mynginx` and expose traffic on port `80`

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

### Get `mynginx` pod's IP address and use a temp `busybox` image to wget its `/` endpoint.

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

### Get the `mynginx` pod's manifest from the cluster and save it in a file called `mypod.yaml`

```sh
k get po/mynginx -oyaml > mypod.yaml
```

### Get information about the `mynginx` pod, including details about potential issues (e.g. pod hasn't started)

```sh
k describe po/mynginx
```

### Get current logs for the `mynginx` pod. Sho how if the pod crashed and restarted you could get logs about the previous instance.

```sh
k logs po/mynginx 
k logs po/mynginx -p
```

### Open an interactive shell in the `mynginx` pod.

```sh
# Review usage
k exec -h

# Open interactive shell 
k exec -it pod/mynginx -- /bin/sh
```

### Create a pod with image `busybox` that echoes 'hello world' and then exits

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

### Create a pod with image `busybox` that echoes 'hello world' to the interactive terminal and then exits, but this time have the pod deleted automatically

```sh
# Review help, I remember something about "--rm" so start there
$ k run -h | grep "\-\-rm" -A 2
    --rm=false:
        If true, delete the pod after it exits.  Only valid when attaching to the container, e.g. with '--attach' or with '-i/--stdin'.


# Run
k run mybox --image=busybox -it --rm --restart=Never --command=true -- /bin/sh -c 'echo hello world'
k get po # nowhere to be found :)
```

### Create an nginx pod and set an env value as 'var1=val1'. Check the env value existence within the pod

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

### Create a Pod with two containers, both with image `busybox` and command `echo hello; sleep 3600`. Connect to the second container and run 'ls'

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

### Create a pod with an `nginx` container exposed on port `80`. Add a `busybox` init container which downloads a page using `wget -O /work-dir/index.html http://neverssl.com/online`. Make a volume of type `emptyDir` and mount it in both containers. For the `nginx` container, mount it on `/usr/share/nginx/html` and for the init container, mount it on `/work-dir`. When done, get the IP of the created pod and create a `busybox` pod and run `wget -O- <IP>`

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

### Create 3 pods with names `nginx1`,`nginx2`,`nginx3`. All of them should have the label `app=v1`

```sh
# Review usage
# Look at options for label
k run -h

# Create pods
$ k run nginx1 --image=nginx -l app=v1
pod/nginx1 created
$ k run nginx2 --image=nginx -l app=v1
pod/nginx2 created
$ k run nginx3 --image=nginx -l app=v1
pod/nginx3 created

# Verify
$ k get pods -l app=v1
NAME     READY   STATUS    RESTARTS   AGE
nginx1   1/1     Running   0          21s
nginx2   1/1     Running   0          17s
nginx3   1/1     Running   0          12s

```

### Display all pods along with their labels

```sh
# Search usage for "show" to discover the "--show-labels" flag
$ k get po -h | grep show
    --show-kind=false:
    --show-labels=false:
        When printing, show all labels as the last column (default hide labels column)
    --show-managed-fields=false:

# Pods with labels
$ k get po --show-labels
NAME     READY   STATUS    RESTARTS   AGE     LABELS
nginx1   1/1     Running   0          4m14s   app=v1
nginx2   1/1     Running   0          4m10s   app=v1
nginx3   1/1     Running   0          4m5s    app=v1
```

### Change the labels of pod 'nginx2' to be app=v2

```sh
# Review usage
k label -h

# Update label 
k label po/nginx2 app=v2 --overwrite

# Verify
$ k get po --show-labels
NAME     READY   STATUS    RESTARTS   AGE     LABELS
nginx1   1/1     Running   0          7m58s   app=v1
nginx2   1/1     Running   0          7m54s   app=v2
nginx3   1/1     Running   0          7m49s   app=v1
```

### Get the label `app` for the pods (show a column with APP labels)

```sh
# Search usage for output formats
# Click link to custom-comlumns
$ k get pod -h | grep '\-\-output' -A 5
    -o, --output='':
        Output format. One of: (json, yaml, name, go-template, go-template-file, template, templatefile, jsonpath, jsonpath-as-json, jsonpath-file, custom-columns, custom-columns-file, wide). See custom columns [https://kubernetes.io/docs/reference/kubectl/#custom-columns], golang template [http://golang.org/pkg/text/template/#pkg-overview] and jsonpath template [https://kubernetes.io/docs/reference/kubectl/jsonpath/].

# Found this example
# kubectl get pods <pod-name> -o custom-columns=NAME:.metadata.name,RSRC:.metadata.resourceVersion

# Use yq to figure out path
$ k get po/nginx1 -oyaml | yq e '.metadata.labels.app' -
v1

# Use example and path to create listing
$ k get po -o custom-columns=Name:.metadata.name,APP:.metadata.labels.app
Name     APP
nginx1   v1
nginx2   v2
nginx3   v1
```

### Get only the `app=v2` pods

```sh
$ k get po -l app=v2
NAME     READY   STATUS    RESTARTS   AGE
nginx2   1/1     Running   0          22m
```

### Add a new label `tier=web` to all pods having `app=v2` or `app=v1` labels

```sh
# Review usage
k label -h

# Search help for Label selectors
# https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors
#
# Note:
# -l app=v1 -l tier=web       - True if app=v1 AND tier=web
# -l app=v1, tier=web         - True if app=v1 OR  tier=web
# -l app=v1 -l app=v2         - WARNING this is the same as -l app=v2

# Note I have to use set notation because the key "app" is the same
# https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#set-based-requirement
$ k label po -l "app in (v1,v2)" tier=web
pod/nginx1 labeled
pod/nginx2 labeled
pod/nginx3 labeled

# Of if I forget set notation just run two commands
k label po -l app=v1
k label po -l app=v2

# Verify
$ k get pod --show-labels
NAME     READY   STATUS    RESTARTS   AGE   LABELS
nginx1   1/1     Running   0          46m   app=v1,tier=web
nginx2   1/1     Running   0          46m   app=v2,tier=web
nginx3   1/1     Running   0          46m   app=v1,tier=web
```

### Add an annotation `owner: marketing` to all pods having `app=v2` label

```sh
# Review usage
k annotate -h

# Add anno
kubectl annotate pods -l app=v2 owner=marketing

# Verify
$ k get po/nginx2 -oyaml | yq e '.metadata.annotations' -
cni.projectcalico.org/containerID: c32a9569ce94dec306d36ac290795b66299dff315b529d977ab69b43c3d16817
cni.projectcalico.org/podIP: 192.168.1.4/32
cni.projectcalico.org/podIPs: 192.168.1.4/32
owner: marketing
```

### Remove the `app` label from the pods we created before

```sh
# Look at the examples
k label -h | grep "Examples:" -A 19

# Select all pods that have an "app" label and remove it
$ k label po -l app app-
pod/nginx1 unlabeled
pod/nginx2 unlabeled
pod/nginx3 unlabeled
```

### Annotate pods `nginx1`, `nginx2`, `nginx3` with `description='my description'` value. Assume the pods have no labels on them

```sh
# Review usage
k annotate -h

# Add anno
k annotate po/nginx{1..3} description='my description'
pod/nginx1 annotated
pod/nginx2 annotated
pod/nginx3 annotated

# Verify
$ k get po -oyaml | yq e .items[].metadata.annotations.description -
my description
my description
my description
```

### Check the annotations for pod nginx1

```sh
# yq
# For me yq is faster to figure out if it is available
k get po -oyaml | yq e .items[].metadata.annotations.description -

# jsonpath 
$ k get po -o=jsonpath='{range .items[*]}{.metadata.annotations.description}{"\n"}' 
my description
my description
my description

# custom-columns
# This one looks the best
$ k get po -o custom-columns=Name:metadata.name,DESC:metadata.annotations.description
Name     DESC
nginx1   my description
nginx2   my description
nginx3   my description
```

### Remove the `description` annotations for the `nginx`, `nginx2` and `nginx3` pods

```sh
# Check your pod selection first
$ k get po/nginx{1..3}
NAME     READY   STATUS    RESTARTS   AGE
nginx1   1/1     Running   0          25m
nginx2   1/1     Running   0          25m
nginx3   1/1     Running   0          25m

$ k annotate po/nginx{1..3} description-
pod/nginx1 annotated
pod/nginx2 annotated
pod/nginx3 annotated

# Verify
$ k get po/nginx{1..3} -oyaml | yq e .items[].metadata.annotations.description -
null
null
null

```

### Remove the `nginx`, `nginx2` and `nginx3` pods to have a clean state in your cluster

```sh
# Delete
$ k delete po nginx{1..3}
pod "nginx1" deleted
pod "nginx2" deleted
pod "nginx3" deleted
```

### Create a pod that will be deployed to a Node that has the label `accelerator=nvidia-tesla-p100`

```sh
# List the nodes and label a worker node
$ k get nodes
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   41d   v1.28.1
node01         Ready    <none>          41d   v1.28.1

k label node/node01 accelerator=nvidia-tesla-p100

# Verify node has label
$ k get node -l accelerator=nvidia-tesla-p100
NAME     STATUS   ROLES    AGE   VERSION
node01   Ready    <none>   41d   v1.28.1

# Search help for node to find nodeName
k explain pod.spec --recursive | grep -i node
k explain pod.spec.nodeName

# Generate yaml
k run myacc --image=nginx --dry-run=client -oyaml > myacc.yamlk run myacc --image=nginx --dry-run=client --oyaml > myacc.yaml

# Add nodeName
vim myacc.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: myacc
  name: myacc
spec:
  nodeName: node01 # Add this
  containers:
  - image: nginx
    name: myacc
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Apply
k apply -f myacc.yaml 

# Verify
$ k get po -owide   
NAME    READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
myacc   1/1     Running   0          24s   192.168.1.7   node01   <none>           <none>
```

### Taint a node with key `tier` and value `frontend` with the effect `NoSchedule`. Then, create a pod that tolerates this taint

```sh
# Review usage
k taint -h

# Add taint
$ kubectl taint node node01 tier=frontend:NoSchedule
node/node01 tainted

k explain pod.spec --recursive | grep -i toler
k explain pod.spec.tolerations

# Search help for toleration to get a good example
# https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"

# Edit manifest to add toleration
vim myacc.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: myacc
  name: myacc
spec:
  tolerations:         # Add toleration
  - key: "tier"
    operator: "Equal"
    value: "frontend"
    effect: "NoSchedule"
  nodeName: node01 
  containers:
  - image: nginx
    name: myacc
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

## Create a pod that will be placed on node `controlplane`. Use `nodeSelector` and `tolerations`

```sh
# Find the controlplane node
$ k get nodes
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   41d   v1.28.1
node01         Ready    <none>          41d   v1.28.1

# Find the taint and labels that identify the controlplane
$ k get node controlplane -oyaml | yq e
...
  taints:
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
...
  labels:
    kubernetes.io/hostname: controlplane
...

# Search usage for nodeSelector
# Note the nodeSelector is a label selector
#   nodeSelector:
#     nodeLabelKey: value
k explain pod --recursive | grep -i nodeSelector
k explain pod.spec.nodeSelector


# Search help for toleration to find this example 
...
  tolerations:
  - key: "key1"
    operator: "Exists"
    effect: "NoSchedule"

# Edit pod manifest to add nodeSelector
vim myctlt.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: myctlt
  name: myctlt
spec:
  tolerations:                                   # Add this
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
  nodeSelector:                                  # Add this
    kubernetes.io/hostname: controlplane
  containers:
  - image: nginx
    name: myctlt
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

# Verify
$ k get po -owide
NAME     READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
myctlt   1/1     Running   0          40s   192.168.0.8   controlplane   <none>           <none>
```

### Create a deployment with image `nginx:1.18.0`, called `nginx`, having `2 replicas`, defining `port 80` as the port that this container exposes (don't create a service for this deployment)

```sh
# Review usage and examples
k create deploy -h

# Create manifest
k create deployment nginx --image=nginx:1.18.0 --dry-run=client --port=80 --replicas=2 -oyaml

# Apply
k apply -f mydep.yaml 

# Verify
$ k get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-584b4f6d78-24mkm   1/1     Running   0          2s
pod/nginx-584b4f6d78-q7629   1/1     Running   0          2s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   41d

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           2s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-584b4f6d78   2         2         2       2s
```

### View the YAML of this deployment

```sh
 k get deploy/nginx -oyaml | yq e
```

### View the YAML of the replica set that was created by this deployment

```sh
k get rs -l app=nginx  -oyaml | yq e
```

### Get the YAML for one of the pods

```sh
# List the pods
$ k get po -l app=nginx  
NAME                     READY   STATUS    RESTARTS   AGE
nginx-584b4f6d78-24mkm   1/1     Running   0          8m58s
nginx-584b4f6d78-q7629   1/1     Running   0          8m58s

# Pick one and display it yaml
k get po/nginx-584b4f6d78-24mkm -oyaml | yq e
```

### Check how the deployment rollout is going

```sh
# Review usage
k rollout -h
k rollout status -h

# Display rollout status
$ k rollout status deploy/nginx 
deployment "nginx" successfully rolled out
```

### Update the nginx image to` nginx:1.19.8`

```sh
# Edit the manifest
k edit deploy nginx # change the .spec.template.spec.containers[0].image

# alternatively...
# Review usage
k set -h
k set image -h

# Set image
k set image deployment/nginx nginx=nginx:1.19.0
```

### Check the rollout history and confirm that the replicas are OK

```sh
$ k rollout history deploy/nginx 
deployment.apps/nginx 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

$ k rollout status deploy/nginx 
deployment "nginx" successfully rolled out

$ k rollout history deploy/nginx 
deployment.apps/nginx 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

$ k rollout status deploy/nginx 
deployment "nginx" successfully rolled out
```

### Undo the latest rollout and verify that new pods have the old image (`nginx:1.18.0`)

```sh
# Review usage and examples
k rollout -h
k rollout undo deploy/nginx 

#Verify
$ k get deploy/nginx -oyaml | yq e '.spec.template.spec.containers[0].image' -
nginx:1.18.0
```

### Do an on purpose update of the deployment with a wrong image `nginx:1.91`

```sh
# Edit manifest
k edit deployment/nginx

# Or set image
k set image deployment/nginx nginx=nginx:1.92
```

### Verify that something's wrong with the rollout

```sh
$ k rollout status deploy/nginx
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...

$ k get rs  -l app=nginx
NAME               DESIRED   CURRENT   READY   AGE
nginx-584b4f6d78   2         2         2       27m
nginx-675b746db7   0         0         0       22m
nginx-bd8859678    1         1         0       5m45s

$ k get pod -l app=nginx
NAME                     READY   STATUS             RESTARTS   AGE
nginx-584b4f6d78-r8wnj   1/1     Running            0          11m
nginx-584b4f6d78-vs6dq   1/1     Running            0          11m
nginx-bd8859678-4w7f5    0/1     ImagePullBackOff   0          6m3s
```

### Return the deployment to the second revision (number 2) and verify the image is `nginx:1.19.8`

```sh
# Review examples
$ k rollout undo -h | grep Example -A 9 
Examples:
  # Roll back to the previous deployment
  kubectl rollout undo deployment/abc
  
  # Roll back to daemonset revision 3
  kubectl rollout undo daemonset/abc --to-revision=3
  
  # Roll back to the previous deployment with dry-run
  kubectl rollout undo --dry-run=server deployment/abc

# Rollback
k rollout undo deployment/nginx --to-revision=2

# Verify
$ k get deploy/nginx -oyaml | yq e '.spec.template.spec.containers[0].image' -
nginx:1.19.0
```

### Check the details of the fourth revision (number 4)

```sh
# Review usage
$ k rollout history -h

# Show details of rev 4
$ k rollout history deploy/nginx --revision=4
deployment.apps/nginx with revision #4
Pod Template:
  Labels:       app=nginx
        pod-template-hash=bd8859678
  Containers:
   nginx:
    Image:      nginx:1.92
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
```

### Scale the deployment to 5 replicas

```sh
# Review usage
k scale -h

# Scale up
k scale --replicas=5 deploy/nginx
```

### Autoscale the deployment, pods between 5 and 10, targetting CPU utilization at 80%

```sh
# Review usage and examples
k autoscale -h

# Create hpa manifest
k autoscale deployment/nginx --min=5 --max=10 --cpu-percent=80 --dry-run=client -oyaml > myhpa.yaml

# Verify
k get pods
```

### Pause the rollout of the deployment

```sh
# Review usage and examples
k rollout -h

# Pause
k rollout pause deployment/nginx
```

### Update the image to `nginx:1.19.9` and check that there's nothing going on, since we paused the rollout

```sh
# Review usage
k set -h

# Change the image
k set image deployment/nginx nginx=nginx:1.19.9

# See that the rollout is not finished
$ k rollout status deployment/nginx -w=false
Waiting for deployment "nginx" rollout to finish: 0 out of 5 new replicas have been updated...

# Confirm "DeploymentPaused"
$ k describe deploy/nginx | grep Conditions -A 4
Conditions:
  Type           Status   Reason
  ----           ------   ------
  Progressing    Unknown  DeploymentPaused
  Available      True     MinimumReplicasAvailable
```

### Resume the rollout and check that the `nginx:1.19.9` image has been applied

```sh
# Review usage 
k rollout resume -h

# Resume
k rollout resume deploy/nginx

# Check status
$ k rollout status deploy/nginx
deployment "nginx" successfully rolled out

# Verify
$ k get po -l app=nginx -oyaml | yq e  '.items[0].spec.containers[0].image' -
nginx:1.19.9
```

### Delete the deployment and the horizontal pod autoscaler you created

```sh
# First list befor you delete
$ k get deployment,hpa
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   10/10   10           10          33m

NAME                                        REFERENCE          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/nginx   Deployment/nginx   <unknown>/50%   10        15        10         2m56s

# Delete
$ k delete deployment/nginx 
deployment.apps "nginx" deleted

$ k delete hpa/nginx        
horizontalpodautoscaler.autoscaling "nginx" deleted

```

### Implement canary deployment by running two instances of `nginx` marked as `version=v1` and `version=v2` so that the load is balanced at 75%-25% ratio

```sh
# Read help: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#canary-deployment

# Review usage and examples
k create deployment -h

# Generate manifests
k create deployment mycan --image=nginx:1.19.0 -r=3 --port=80 --dry-run=client -oyaml > mycan-deploy2.yaml
k create deployment mycan --image=nginx:1.18.0 -r=9 --port=80 --dry-run=client -oyaml > mycan-deploy1.yaml

# Edit manifests to make the deployment names unique
# Could use vim to edit instead
sed -i 's/name: mycan/name: mycan1/g' mycan-deploy1.yaml
sed -i 's/name: mycan/name: mycan2/g' mycan-deploy2.yaml


# Apply
k apply -f mycan-deploy1.yaml
k apply -f mycan-deploy2.yaml

# Check to see that all pods are under the common label
k get pods -l app=nx

# Review usage and examples
k create service -h
k create service clusterip -h

# Generate manifest
k create service clusterip mycan --tcp=80:80 --dry-run=client -oyaml > mycan-svc.yaml

# Apply
k apply -f mycan-svc.yaml 

# Verify the service SELECTOR is "app=mycan"
$ k get svc/mycan -owide
NAME    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
mycan   ClusterIP   10.111.77.10   <none>        80/TCP    38s   app=mycan

# Then verify that all pods show up under this selector
# This means that the service is loadbalancing to pods in a round robin fassion
# at a ration of 3:1
#
$ k get po -l app=mycan
NAME                      READY   STATUS    RESTARTS   AGE
mycan1-764f57dfcd-65msn   1/1     Running   0          3m39s
mycan1-764f57dfcd-6txwl   1/1     Running   0          3m39s
mycan1-764f57dfcd-7z8dr   1/1     Running   0          3m39s
mycan1-764f57dfcd-8fbr9   1/1     Running   0          3m39s
mycan1-764f57dfcd-fv644   1/1     Running   0          3m39s
mycan1-764f57dfcd-h8hjb   1/1     Running   0          3m39s
mycan1-764f57dfcd-n6c9g   1/1     Running   0          3m39s
mycan1-764f57dfcd-pwb69   1/1     Running   0          3m39s
mycan1-764f57dfcd-wsdks   1/1     Running   0          3m39s
mycan2-855f78f44c-flnd4   1/1     Running   0          3m39s
mycan2-855f78f44c-h2sz7   1/1     Running   0          3m39s
mycan2-855f78f44c-nqxbf   1/1     Running   0          3m39s
```

### Implement canary deployment by running two instances of `nginx` marked as `version=v1` and `version=v2` so that the load is balanced at 75%-25% ratio, but this time make is so the deployment respond with `version-1` and `version-2` respectivly

```sh
# Review usage and examples
k create deployment -h

# Generate manifests
k create deployment nxa --image=nginx:1.18.0 -r=9 --port=80 --dry-run=client -oyaml > nxa.yaml

# Find index.html path
$ k exec -it po/nxa-5dbb8f8f9c-24967 -- sh
% find . | grep index.html
./usr/share/nginx/html/index.html


# Search kubernetes.io/docs
#   - find emptDir volume example
#   - find init container example
#
# Edit deployment to add emptyDir volume at /usr/share/nginx/html/index.html
# add init container to populate index.html

vim nxa.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nx
  name: nxa
spec:
  replicas: 9
  selector:
    matchLabels:
      app: nx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nx
    spec:
      initContainers: # add initContainer
      - name: init
        volumeMounts:
         - mountPath: /usr/share/nginx/html
           name: data
        image: busybox:1.28
        command:
        - /bin/sh
        - -c
        - echo version-1 >  /usr/share/nginx/html/index.html
      volumes:       # add emptyDir vol
      - name: data
        emptyDir: {}
      containers:
      - image: nginx:1.18.0
        name: nginx
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: data
        ports:
        - containerPort: 80
        resources: {}
status: {}


cp nxa.yaml nxb.yaml

vim nxb.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nx
  name: nxb  # Change deployment name
spec:
  replicas: 3 # Change replicas
  selector:
    matchLabels:
      app: nx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nx
    spec:
      initContainers:
      - name: init
        volumeMounts:
         - mountPath: /usr/share/nginx/html
           name: data
        image: busybox:1.28
        command: 
        - /bin/sh
        - -c
        - echo version-2 >  /usr/share/nginx/html/index.html 
      volumes:
      - name: data
        emptyDir: {}
      containers:
      - image: nginx:1.19.0 # chane image
        name: nginx
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: data
        ports:
        - containerPort: 80
        resources: {}
status: {}

k apply -f nxa.yaml 
k apply -f nxb.yaml

# Verify that index.html has been update, pick any pod
$ k exec pods/nxa-78f585dbcd-7vmc7 -it -c nginx -- cat /usr/share/nginx/html/index.html
version-1

# Make sure all 12 pods are listed under the common label
k get po -l app=nx

$ k get po -l app=nx | grep nxa | wc -l
9
$ k get po -l app=nx | grep nxb | wc -l
3

# Review usage and examples
k create service -h
k create service clusterip -h

# Generate manifest
k create service clusterip nx --tcp=80:80 --dry-run=client -oyaml > nxsvc.yaml

# Apply
k apply -f nxsvc.yaml 

# Hit the service
k run  test -it --rm --image=busybox --command -- /bin/sh -c 'while true;do wget -O - -q  http://nx; sleep 1; done'
```

### Create a job named `pi` with image `perl:5.34` that runs the command with arguments `perl -Mbignum=bpi -wle 'print bpi(2000)'`

```sh
# Review usage and examples
k create job -h

# Generate manifests
k create job mypi --image=perl:5.34 --dry-run=client -oyaml -- perl -Mbignum=bpi -wle 'print bpi(2000)'  > mypi.yaml

# Apply
k apply -f mypi.yaml

# Verify
$ k logs po/mypi-x4vnc
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275901
```

DEVTODO left off here https://github.com/dgkanatsios/CKAD-exercises/blob/d5a1a2bee71658784f4d5e15130dc90daa023826/c.pod_design.md?plain=1#L590C1-L590C148


DEVTODO - left off here









### Create a namespace called `ggckad-s0` in your cluster.

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


