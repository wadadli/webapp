# Terraform autosclaing infrastructure
This repository contains code that will deploy an autoscaling infrastructure on AWS. It includes a simple web app that I wrote in rust which will connect to a Amazon Relational Database Service.

The current topology is :

1. a /16 virtual private cloud
2. a public subnet per availability zone,
3. a private subnet per availability zone,
4. a database subnet per availability zone,
5. two nat gateways for each private subnet,
6. an application load balancer per availability zone,
7. an austoscaling group that deploys several ec2s,
8. a relational database service per availability zone,


Provided that the user is familiar with terraform and has their environment configured correctly, simply clone this repository and run:

```
cd infra && terraform init && terraform plan
```

The ```infra``` dir contains ```Dockerfile``` which builds a container used to statically link the rust binary with musl using rustc nightly compiler.

You can build this container as per normal using docker then run ```docker run --rm -it --volume "$(pwd)":/home/rust/src:Z wadadli/nightly-rust-muslc-builder cargo build --release```

The "Z" options on the volume mount (--volume) is important, for the container to have access to files in the host dir

"Z" will label the content inside the container with the exact MCS label that the container will run with, basically it runs ```chcon -Rt svirt_sandbox_file_t -l s0:c1,c2 $PWD``` where s0:c1,c2 differs for each container.

The final artifact will be located in ```target/x86_64-unknown-linux-musl/release/```

If it was built successfully ```ldd``` will report:
> not a dynamic executable

---


The ```Dockerfile``` in the root dir builds the application container that ```infra/user_data.sh``` will configure each ec2 instance in the autoscaling group to server on ```0.0.0.0/0:80```
