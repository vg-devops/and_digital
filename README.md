Welcome to my Test Project for Setting Up Infrastructure and Load Balancer
as per the project scope of work defined below:

    1] - Build via terraform a load balancer with three servers into different availability zones
    2] - They must be secure in a vpc

To initialize my project, please ensure that 
1. you created an S3 bucket: vg-devops-rs12345 within region = "eu-west-1"

2. cd into infrastructure/ folder and run terraform init

3. run there terraform apply

4. cd into web_elb0 folder and run terraform init

5. run there terraform apply

Note: you can play with variables, bucket names etc by changing these in the relevant files or pre-setting via <var="varname=value">


