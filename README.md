<p align="center">
<img src="https://sonarcloud.io/api/project_badges/quality_gate?project=omersiar_go-microepoch"
</p>

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=omersiar_go-microepoch&metric=alert_status)](https://sonarcloud.io/dashboard?id=omersiar_go-microepoch) 
[![Go Report Card](https://goreportcard.com/badge/github.com/omersiar/go-microepoch)](https://goreportcard.com/report/github.com/omersiar/go-microepoch)
![docker](https://img.shields.io/badge/docker-18.06-blue.svg) 
[![Build Status](https://travis-ci.org/omersiar/go-microepoch.svg?branch=master)](https://travis-ci.org/omersiar/go-microepoch) ![Kuburnetes](https://img.shields.io/badge/kubernetes-1.13.3-informational.svg) 
![GitHub last commit](https://img.shields.io/github/last-commit/omersiar/go-microepoch.svg) 
[![Website](https://img.shields.io/website-up-down-green-red/http/epoch.bitadvise.com.svg)](http://epoch.bitadvise.com)

# A complete DevOps cycle for a Go Application which lives on Kubernetes cluster.
In this example we will focus on creating an elegant solution using several higher-level services/software which renders our application an agile, continuously integrated and delivered microservice that lives on [Kubernetes (k8s)](https://kubernetes.io/) cluster. 

[![tBW1f.png](https://i.imgyukle.com/2019/03/04/tBW1f.png)](https://imgyukle.com/i/tBW1f)

As we start preliminary with simple code, it grows into something bigger **-an auto scaled, revision controlled, containered, globally distributed microservice-**. There are nearly hundreds (even thousands when combined) of different ways to accomplish what we are doing here, so I am going to focus on providing mixture of approaches, methods rather than giving examples of command line arguments.

Let's begin.

## Go Application
Our journey to the clouds begins with a minimal [*Go*](https://golang.org/) application ([main.go](https://github.com/omersiar/go-microepoch/blob/master/main.go)) that simply serves a [Unix Timestamp](https://en.wikipedia.org/wiki/Unix_time) as JSON formatted plain text which can be used to sync the time between Kubernetes nodes or with other services.

<p>
<details><summary><b>What is a unix timestamp and why should you use it?</b></summary><br>

---

A Unix Timestamp represents a point in time (time elapsed since January 1, 1970 00:00 UTC) regardless of region, time-zone or any systemic or cultural differences. A timestamp is always useful when a time critical task is carried on like in this example.

---

</details>
</p>

```JSON
{
	"type": "epoch",
	"data": 1552299848,
	"unit": "sec",
	"rev": "574cb4c"
}
```
*program output (pretty formatted)*

<p>
<details><summary><b>Why JSON?</b></summary><br>

---

JSON formatted text can be easily parsed by a machine even if it has minimal resources. JSON also easy to read and write by humans as well.

---

</details>
</p>

A Unix timestamp microservice can be used in various cases, in this case we assume that we needed it for our [**TOTP** (Time-Based One-Time Password)](https://www.ietf.org/rfc/rfc6238.txt) services to work reliably. 

<p>
<details><summary><b>On TOTP</b></summary><br>

---

TOTP algorithm is widely used by 2-step authentication mechanisms (2FA, 2-step verification, multi-factor authentication).

---

</details>
</p>

I chose Go Language because of [its exponential growth](https://blog.golang.org/8years) in popularity and of course for its deliverability. 

Go applications can be executed within incredibly small containers, once you link all the dependencies to the executable, you would not need Go runtimes to run your application, after all, Go is essentially designed for cloud computing.

<p>
<details><summary><b>Containerization</b></summary><br>

---

Containerization term comes from logistics, means packaging payloads (goods) in a standardized way. With containerization we can make sure that the software can be transported anywhere regardless which runtime is going to consumes it (Docker, LXD, containerd, rkt).

Docker is not the only containerization option but makes everyone's life **very... very...** easy thus we understand why it is so [popular](https://www.datadoghq.com/docker-adoption/).

---

</details>
</p>

Of course, you can choose any other programming languages for a microservice, they have all have pros and cons and these are beyond of this article's context. For those who may ask what to choose, these are the programming languages that can be used to build fast, scalable microservices:

* Javascript
* Python
* Java
* Ruby
* PHP
* C++  

*sorted by popularity*

Our go app does not take into account any time drifts (that may caused by network lag, jitter) so it's not expected to have atomic clock grade performance (small differences can be ignored since TOTP spec. recommends 30 seconds window), if you want discover how networked, IP based devices get their clock synced, please check [Cisco's Network Time Protocol Best Practices](https://www.cisco.com/c/en/us/support/docs/availability/high-availability/19643-ntpm.html)  

## Docker
Our go app is intended to be built on a Docker container ([golang](https://hub.docker.com/_/golang)), then compiled binary copied to Docker's empty ([scratch](https://hub.docker.com/_/scratch)) image in order to have a minimal Docker image to run.  

<p>
<details><summary><b>Does it really going to be build in a container?</b></summary><br>

---

Yes, and this makes great example of using containers. 

Think of a case that you are in the hurry (or on the go) and your team expect you to fix a bug asap, but you do not have the development environment or time to setup a new environment. 

Let's think of another case, with usage of containers anyone can checkout your code base and make modifications without hesitation of getting their computer bloated. 

Also it makes automation really simple, no need to worry about mixing configuration with another project, etc.

---

</details>
</p>

Since we are linking go dependencies (libraries) to the binary, final image can be executed like any other Docker image. It gets executed with no privileges, so we can say that it is secure in its simplicity (You [should not](https://en.wikipedia.org/wiki/Principle_of_least_privilege) run applications with root privilege in a container, to conform [security by design principles](https://www.owasp.org/index.php/Security_by_Design_Principles) ([Wikipedia Link](https://en.wikipedia.org/wiki/Secure_by_design)), a process should only have access to the resources it needs and nothing more). 

Also we need to serve our built Docker images so our Kubernetes cluster will able download it, of course we could have used one of the Public Registries like [Docker Hub](https://hub.docker.com/) or [Google's Container Registry](https://gcr.io) but in the context of Proprietary Software we would not want to use a public registry, instead we are going to create our Private Registry for our docker images.

Creating a private docker registry is relatively an easy task, just follow the [instructions here](https://docs.docker.com/registry/deploying/). While we are putting this example to reality, we omit some fundamental necessity for a Private Registry due to the sake of quickness - **Authentication**. [Docker Registry Authentication Specification](https://docs.docker.com/registry/spec/auth/token/) allows us to build variety of authentication mechanisms on top of it, companies should choose their corresponding authentication approach.

<p>
<details><summary><b>Kraken - Uber's Docker Registry</b></summary><br>

---

Uber’s Cluster Management team developed [Kraken](https://github.com/uber/kraken), an open source, peer-to-peer (P2P) Docker registry. Docker containers are a foundational building block of Uber’s infrastructure, but as the number and size of our compute clusters grew, a simple Docker registry setup with sharding and caches couldn’t keep up with the throughput required to distribute Docker images efficiently.

![](https://1fykyq3mdn5r21tpna3wkdyi-wpengine.netdna-ssl.com/wp-content/uploads/2019/03/image3.gif)

With a focus on scalability and availability, Kraken was designed for Docker image management, replication, and distribution in a hybrid cloud environment. With pluggable back-end support, Kraken can also be plugged into existing Docker registry setups as the distribution layer.

*(from Uber's blog)*

---

</details>
</p>


I have already deployed a private registry at one of my cloud server and available behind a [nginx Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/). This does not make an impact on our workflow except the URL link to pull/push the Docker image, if you want use one of Public Registries you are good to go.

Our Private Docker Registry is located at: bitadvise.com

### Make
In [GNU](https://www.gnu.org/) scene [**make**](https://www.gnu.org/software/make/) is a powerful software tool for building/installing/uninstalling an executable. Our Makefile defines some options for our workspace (repository) so end-users (includes ourself) can quickly give commands without needing to know all the details about what actual command does.

Simple `make build` command will build a docker image, and `make run` runs our latest image on Docker container.

```shell
usage: make [target]

build                          - Build go-microepoch Docker image (this also updates staging image on docker registry if it is built on Travis)
build-no-cache                 - Build go-microepoch Docker image with --no-cache option enabled
deploy                         - Deploy image to bitadvise.com Registry and update K8s app image (Production)
help                           - Show targets
run                            - Run go-microepoch and publish on TCP 8080 port (detached)
```

## Travis CI / CD
In this case our Continuous Integration / Delivery service is [Travis](https://travis-ci.org), one of the most popular CI/CD services and it is free for open source projects. 

*(It could have been one of popular services/software like [Jenkins](https://jenkins.io/), [Bamboo](https://www.atlassian.com/software/bamboo) it would not change our workflow). (You may also use git's [post/pre commit hooks](https://www.atlassian.com/git/tutorials/git-hooks) for local automated builds).*

Thanks to automated services we do not need any development environment for our Go application, one can simply push changes to the git repository (via WebIDE or even mobile phone) then it can be built by an automated Continuous Integration system, this enables us to work with virtually on any device and anywhere in the world.

<p align="center">
  <img src="https://i.imgyukle.com/2019/03/11/FvH30.png">
</p>

<p align="center">
simplified workflow
</p>

Our CI pipeline starts with a [.travis.yml](https://github.com/omersiar/go-microepoch/blob/master/.travis.yml) file, Travis uses this file in order to run our pipeline in a Virtual Machine. When a commit is pushed to the git repository, Travis boots up a Clean VM, prepares building environment and builds our Docker image and in the case of commit is pushed to "master" branch it also pushes image to our Docker Private Registry and finally rolls an update on the Kubernetes cluster.

We use Travis' secure, protected [repository variables](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings) to pass our Kubernetes' service account tokens to the [Bash script](https://github.com/omersiar/go-microepoch/blob/master/kubeEnv.sh).

## Kubernetes
Kubernetes cluster in this example is provided by [Google Cloud Platform](https://cloud.google.com/), again, it does not matter which cloud service you host your Kubernetes cluster on, either choose one of the best [Certified Kubernetes Providers](https://kubernetes.io/partners/#conformance) like [Amazon's EKS ](https://aws.amazon.com/) and [DigitalOcean](https://digitalocean.com/) or create your mini cluster with [minikube](https://github.com/kubernetes/minikube) locally.

Our Kubernetes cluster configuration is as below:

* Our cluster is in a Data Center located at Netherlands
* It consists from three nodes and one load balancer service (nginx Ingress)
* There are two namespaces for **Production** and **Staging**
* Our production deployment is named as **epoch-app** which is updated whenever the *master* branch is changed
* Our testing deployment is named as **epoch-test** which is updated whenever developers commit to the *staging* branch
* We expose the deployments through **nginx Ingress**
* We have two service accounts for **Continous Deployment** for both namespaces

When we merge/push changes to "master" branch on our git repository, Travis tells Kubernetes cluster to change the application image via kubectl. Kubernetes then tries to roll out our new image to across its pods, thanks to Kubernetes internal workings there is no downtime introduced by an update (Kubernetes first creates new pods with updated image, then checks their health, if they are in good condition, it deletes previous pods and redirects traffic to the new pods), and our new version of Go Application will be on air in a few minutes without disrupting clients.

### Deployment Types

In this example we are using rolling update strategy to serve freshly coded application. New features that are coded by developers are tested on their explicit service without a split second downtime. Some industry best practices also available for application deployment like **Blue - Green Deployment** and **Canary Deployment**.

Congratulations, now we can access our freshly updated microservice. Please notice that we have **"revision"** element on application's output, so it matches with the repository's latest SHA1 commit id (short type). You can also use reverse proxy service like [Cloudflare](https://www.cloudflare.com/) to access our microservice within a namespace (domain) or you can create a new "A" record on your DNS server.

Click and check it out how cool it is:  

http://epoch.bitadvise.com (Production, master branch)  

http://test.epoch.bitadvise.com (Testing, staging branch)

### TODO
- [ ] Write test for "Inspect the container to determine if it is really running"
- [ ] Write test for "If timestamp matches with expected regex"
- [ ] Create another cluster on different cloud provider then sync two Kubernetes clusters together (federation is still in beta)
- [x] Switched to the Google Cloud DNS (auto Ingress DNS naming, CA certification)
- [x] Create a Kubernetes Ingress (nginx)
- [x] Arrange Kubernetes secrets for RBAC or ABAC (~~possibly ABAC in this headless setup~~) (ended up with setting up two roles for both namespaces)
- [x] Separate Production and Staging environments on same Kubernetes cluster using namespaces
- [x] Redirect "epoch.bitadvise.com" to Kubernetes load balancer
- [x] Provide more learning materials