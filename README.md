# blue-bucks-diner-backend
The backend for Blue Bucks Diner mobile app.

Mainly following [this post](https://itnext.io/building-restful-web-apis-with-node-js-express-mongodb-and-typescript-part-1-2-195bdaf129cf).

Goal: Node.js + MongoDB for RESTful as an universal backend.

## Global & 3rd Party Tools Setup

- ~~`npm install -g typescript ts-node`~~

- Install [MongoDB](https://treehouse.github.io/installation-guides/mac/mongo-mac.html).

```sh
brew update
brew install mongodb
~~mkdir -p /data/db~~
~~sudo chown -R `id -un` /data/db~~
# enter sudo password

# To have launchd start mongodb now and restart at login
brew services start mongodb

# run mongo daemon
mongod

# (optional) run mongo shell
mongo
```

- Install a GUI for MongoDB. You can choose Robo 3t / Studio 3t or MongoDB Compass

```sh
brew cask install mongodb-compass-community
```

- MongoDB's ORM -- mongoose! `npm i mongoose`

- A REST API inspector, like Insomnia, or Postman.

```sh
brew cask install insomnia
```

- Hot reload! Nodemon `npm i -D nodemon`


- Can use "dotenv" to hide credential in environment variable.

```
npm i dotenv
```

We have a `credentials.env` in the root. Make sure you specify the file path like this:

```js
require('dotenv').config({
    path: "credentials.env"
});
```

- AWS command line tool. This is a pip package, so you can install in globally or just use [virtual environment](https://docs.aws.amazon.com/cli/latest/userguide/install-virtualenv.html). Global install may make more sense for cli tool, but the doc didn't mention any side effects to install in virtual environment so we'll use that.

```sh
pip install --upgrade awscli
aws configure
# our default region name is us-east-1
```

- Docker
    - Build an image. `docker build -t <image-title: bb-rest-api> .`
    - List all images. `docker images`
    - List all containers. `docker container ls`
    - List all running containers `docker container ps`
        - Stop that running container `docker stop <container ID>`
    - Stop container. `docker stop {image-id}`

## Setup AWS EC2 Container Service (ECS)

This part largely follows this [FreecodeCamp post](https://medium.freecodecamp.org/how-to-deploy-a-node-js-application-to-amazon-web-services-using-docker-81c2a2d7225b), which is originated from [Nodejs University's post](https://node.university/blog/10067/aws-ecs-containers) with more screenshots. However they do not cover some steps in the creating service part.

### Create Container's Repo on ECR

- Create a repo on ECS. Right after the creation, you'll see a green notification bar on top, press `View Push Commands` to get access to the instruction to push docker image to this repo. Follow the instrcutions there and run those command in your local dev project.

```sh
$(aws ecr get-login --no-include-email --region us-east-1)
# Login Succeeded 

docker build -t bb-rest-api . # skip this if your image already built

# tag your image to set it as dest to push to
docker tag bb-rest-api:latest 368061806057.dkr.ecr.us-east-1.amazonaws.com/bb-rest-api:latest

# from now on, push this image to the aws repo
docker push 368061806057.dkr.ecr.us-east-1.amazonaws.com/bb-rest-api:latest

```

### Create Task Definition

- Create task definition (for managing multiple containers).
    - Press `create task definition` in the aws web console.
    - Give a task definition name. (We use `bb-task`)
    - Add a container. A form will show up to fill in
        - Container name - use our image title name `bb-rest-api`
        - Image - fill in the image url, in our case, `368061806057.dkr.ecr.us-east-1.amazonaws.com/bb-rest-api`
        - "Private repository authentication": [not appliable](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html) if using ECR as the repo with ECS.
        - Add a memory soft limit as 512. (Following [the tutorial](https://medium.freecodecamp.org/how-to-deploy-a-node-js-application-to-amazon-web-services-using-docker-81c2a2d7225b)). "Soft limit: ECS reserves that amount of memory for your container."
        - Port mapping: map host 80 to containter 3000. TCP is fine.
        - Go to "ENVIRONMENT" section, scroll down to locate `Environment variables` subsection.
            - NODE_ENV: production
            - MONGODB_URI: `your db connection url w/ credentials`
        - Submit the form to add container.
    - Press "Create" to submit the task definition form.

- You can also self-host a mongoDB in one of the containers, and use task definition to glue them to run together in a cluster. [Read from this post](https://codeburst.io/a-complete-guide-to-deploying-your-web-app-to-amazon-web-service-2854ff6bc399), or [directly jump to the screenshot step-by-step setting post](https://node.university/blog/10067/aws-ecs-containers).

### Create Cluster

- Press create cluster in the aws web console.
- Three template options show up: networking, linux ec2+networking, or Windows ec2+networking. Here I chose "linux ec2+networking". (not sure if this is the best, but since it's a template we suppose to be able to modify things in the next step)
- Give a cluster name, our case `bb-cluster`
- On-demand or spot? [Your instance can get terminated anytime](https://www.quora.com/What-is-the-difference-between-a-spot-instance-and-a-demand-instance-on-EC2) by aws. Sounds creepy but if you have a [back up instance](https://blog.boltops.com/2018/07/13/on-demand-vs-reserved-vs-spot-aws-ec2-pricing-comparison), it'll be useful and save a lot of money. We jsut have one instance, we go for on-demand anyway.

- EC2 instance type=`t2.micro`, which is the smallest.
- Num of instance=1 (default)
- EBS storage=22 (default)
- Key pair: leave as empty (None) (default)
- VPC: create new (default)
- Create cluster. Wait for it to finish. Once completed, you can press the button "View Cluster".

### Create Service

Task grabs containers. Now service picks up the task and puts it into a cluster to run. Service also does maintanance works.

- Create service under a task. In aws web console, go to task definition > the task we created > choose latest version (the largest number?) > and click on the "Action" dropdown menu.
    - Fill in the form:
        - Lanuch type=EC2
        - Give a service name `bb-service`
        - Set number of tasks=1 (Use service type Replica)
        - Minimum healthy percent=0 ([See this post](https://docs.bitnami.com/containers/how-to/ecs-rds-tutorial/) for explanation)
        - Skip the rest and click next.
    - Configure network form. The original tutorial does not cover this part.
        - You can just select `None` for the `Load balancing` option.
            - "Tasks for services that do not use a load balancer are considered healthy if they are in the RUNNING state." – [AWS Doc](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/update-service.html).
            - Ngnix is one kind of the Load Balancer. If you use aws's load balancer, you don't need it.
        - Service discovery integration: not sure what this can do. We'll disable it now.
        - Click next
    - We'll choose `Do not adjust the service’s desired count`. Next Step.


## Creating a CI/CD pipeline

- Install Terraform. `brew install terraform`.

# Summarizing CI/CD

- Setup ECR repo (one-time action), get the ECR url and put that in `.env`. **Remember, just the base url, not the repo name included, exclude the repo name.**
- (we will eventually push docker image to ECR by AWS CodeBuild in CodePipeline) we now build and push our docker image for setup purpose.
    - `docker-compose build`, test by `docker-compose up -d` and upload to ECR by `docker-compose push`. You might want to do `$(aws ecr get-login --no-include-email --region us-east-2)` first.
- Create the task definition - container - service series of resources in ECS. This is a one-time action. We will need `ecs-cli`, `docker-compose-ecs.yml`, `Dockerfile`, and most important, `ecs-params.yml`. **You probably want a separate `docker-compose-ecs.yml` for ECS**, because they use different method from local dev to pass in secrets and env variables.
    - If you're not sure what to specify in `ecs-params.yml`, refer to the ECS task definition wizard.
    - Apply by `ecs-cli compose --debug --file docker-compose-ecs.yml --project-name BBDiner --ecs-params ecs-params.yml --cluster-config ApplTrackyConfig --cluster ApplTrackyCluster service up --create-log-groups`
- Once you get the container instance on ECS spin up, and being able to access the website, congrats! You're almost there.
- Setup the AWS CodePipeline using the wizard provided in the AWS web portal.
- Make changes to Github repo and see the CI/CD completed!

- Next time:
    - We now setup a CI/CD, but, we can't access the server cuz of routing.
        - only one public IP per constainer instance. If you want to rely on ALB, you have to use suffix url, which, can't be done by simply adding a record to Route 53.
        - To maximize route53 use, you can only create another container instance, which means, you have to create another cluster. 
        - configure `ecs-cli configure --cluster BBDinerCluster --region us-east-2 --default-launch-type EC2 --config-name BBDinerConfig`
        - create cluster `ecs-cli up --debug --keypair shaungc-ecs --capability-iam --launch-type EC2 --size 1 --instance-type t2.micro --azs us-east-2a,us-east-2b --image-id ami-04b61a4d3b11cc8ea --force --cluster-config BBDinerConfig --cluster BBDinerCluster`
        - create all the resources `ecs-cli compose --debug --file docker-compose-ecs.yml --project-name BBDiner --ecs-params ecs-params.yml --cluster-config BBDinerConfig service up --create-log-groups`

- Next time:
    - we want to route to BB using ALB. Seems like we already have a working BB service w/o LB. But we need LB <-- https <--53 ssl cert.
    - Keep trying to setup LB-ver BB service.
    - Conclusion: when using with LB, then same as w/ Ngnix - node.js has to always use 3000, and container settings always use 3000, for health check, for host/container port, all use 3000! And also config LB to listen to 80 port -> 80 Target group && listen to 3000 port -> 3000 Target group. Set Target group's health check to use `traffic port`.

- 🔥 Some ideas why health check failed.
    - [When following this article to debug](https://aws.amazon.com/premiumsupport/knowledge-center/troubleshoot-unhealthy-checks-ecs/), I noticed that the EC2 instance security group by default is also blocking connections. After attaching appropriate security group to it, we can now `ssh` into it. However, the service and task is still failing. Why?

# Reference

- [A beginner’s guide to Amazon’s Elastic Container Service](https://medium.freecodecamp.org/amazon-ecs-terms-and-architecture-807d8c4960fd): terms like cluster, service, tasks, and good paradigm pictures!

- Terraform - use it to automate settings on AWS ECS.
- [Self ref link to this repo](https://github.com/rivernews/bb-rest-api)
- About PORT
    - [You cannot listen to port 80](https://stackoverflow.com/questions/18947356/node-js-app-cant-run-on-port-80-even-though-theres-no-other-process-blocking-t), so node.js has to listen to 3000.
- [Too `ssh` into the container instance](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance-connect.html), follow the article.
- [`docker-compose-ecs.yml`](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-parameters.html) file spec.
- [`ecs-params.yml`](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-ecsparams.html) file spec.
- [`docker-compose.yml`](https://docs.docker.com/compose/compose-file/compose-file-v2/#cpu-and-other-resources) file spec.