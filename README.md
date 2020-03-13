The following is the set of instructions for using this code correctly
assuming the root dir referenced in the code below is yelp_analysis/. This file
lies directly under this directory.


You will be automatically creating infrastructure using Terraform and Ansible!
To do so correctly, please follow the instructions below!


---------------------------- AWS and SSH Access --------------------------------
1.) Make sure you have a working AWS account with users and associated access keys:
        AWS_SECRET_ACCESS_KEY & AWS_ACCESS_KEY_ID
    Add these keys to the following file:
        ec2/access_keys_template.sh
    Add them into your environment by running:
        . ec2/access_keys_template.sh.
    Verify by using 'printenv' in your terminal.
    These keys should have sufficient permissions to create, modify and remove
    infrastructure. For test purposes, I used a user with admin permissions
    since the key is NEVER sent into the cloud and only used locally.

2.) Create an ssh key pair in AWS called 'ssh-access' using 'pem'. Once created
    move the downloaded pem file into your local ~/.ssh/ directory. Remember
    to set the appropriate permissions with:
        chmod 400 ~/.ssh/ssh-access.pem
    Next add the key to your ssh agent by running:
        eval `ssh-agent`
        ssh-add -k ~/.ssh/ssh-access.pem
    You will need this when running ansible for ssh access.


---------------------------- Setting up Terraform ------------------------------
3.) Now set up terraform in your local environment by running:
        cd ec2/terraform
        ./install_terraform.sh
    This will just download the `terraform` executable. This will not modify your
    system itself. Assuming step 1 is done, you should be able to run:
        ./terraform init
        ./terraform plan
    After running the plan, you should see something like:
        Plan: 4 to add, 0 to change, 0 to destroy.

        ------------------------------------------------------------------------
    with other output above it. This is indicating that 4 different AWS resources
    are going to be created if we run the command to create them (which we will
    soon). Now you have terraform setup to work but only in the directory:
    'ec2/terraform'.


---------------------------- Setting up Ansible --------------------------------
4.) Now set up ansible by doing the following:
    Create a virtual environment in a location of your choice and install
    the yelp_analysis/requirements.txt file in that environment. Ansible is
    a part of those packages. Assuming you have your `ssh-access.pem` key
    in your agent, you should be able to SSH into an instance created with
    our terraform code now with Ansible.


---------------------------- Running the ETL & Analysis ------------------------
5.) To run the data migration, run the following assuming all 4 steps above
    have completed and are active in your current environment (this should apply
    to both mac and linux users without any special instructions).

    a.) First we will setup an EC2 instance in your default VPC of us-west-2
        (Oregon) in the 2a AZ with an EBS volume of 32GB for our database, a
        security group that will allow SSH access and access to port 8000
        for jupyterhub. Run the following command in 'ec2/terraform' and enter
        yes when prompted to do so:
            ./terraform apply
        Note that there will be output of the public IP of that instance at the
        end of the command. We will use this IP with Ansible to tell it what
        instance to modify. Output example:
            Outputs:
            
            public_ip: XXXXXXXX                         
        The instance name will be yelp-analysis and can be found in the us-west-2
        EC2 dashboard.

    b.) Second, use the public IP associated with the instance that was in the
        output of the previous command and modify the following file:
        `yelp_analysis/ec2/ansible/hosts`
        Make sure that the IP under [mongo] is changed to this value else
        Ansible will not be able to find our newly created instance. Once that
        is done, we can run the following file starting in the directory
        yelp_analysis/ec2/ansible
            ./setup_instance.sh
        This file will install:
        - MongoDB
        - Migrate the yelp data from a public S3 bucket and insert into the DB
          with indices applied
        - Install jupyterhub
        - Move our analysis workbook to the proper location

        
        Make sure to keep watch of the run and answer `yes` to connect via SSH.
        Make sure to simply press Enter when prompted for a jupyterhub password!
        
        
        You will see [WARNING] with ansible but that is okay. If you are having
        SSH connection issues, make your the 'ssh-access.pem' key is in your ssh
        agent. If there are other issues that are suspected to be intermittent,
        try again by doing:
            ./terraform destroy
        to bring the instance down and then rebuild using:
            ./terraform apply
        to bring another instance back up. Remember to copy the public IP
        and update 'ec2/ansible/hosts' with the IP address. In general, if you
        see an issue just use terraform to destroy and bring back up the
        deploy.

    c.) When finished with all of the above, go to your browser and type in:
        <public ip>:8000
        Log in with the user `jupyter` and no password. You should be able to
        see the notebook there and open up the yelp data analysis. Note that
        the connection will not be SSL encrypted which would not be good for
        a production system. This is okay for now to demonstrate the
        deployment but should be modified in the future. Open up the notebook
        and you should be able to run code, if desired. The analysis is
        present there with the write-up/report.

    d.) Note that the notebook is also present in 'yelp_analysis/' as Yelp-
        Data-Analysis.ipynb so that can be brought up locally with a simple
        jupyter notebook deploy to a virtual environment.

    e.) When finished, run:
            ./terraform destroy
        in ec2/terraform to remove the infrastructure.


---------------------------- Technical Notes -----------------------------------

- I decided to use mongodb because I wanted faster development time for the
analysis portion. This essentially gave me a schema-on-read option rather than
enforcing the data integrity database side. While this was good when it came
to migrating data, this hurt me when I couldn't use the database to join. I
overcame that by essentially joining in the analysis code itself. Also the full
dataset was only ~8 GB meaning we didn't have to think about distributed
solutions, at least in a beginning scope.

- I wanted to use jupyter notebooks since it would have been a good approach
to encapsulating data preparation with the analysis combined into a report-like
structure.

- There is room to consider perhaps using some sort of Spark/Hadoop cluster
  for this data. I decided to use a more economical approach with a simple
  EC2/DB instance. I don't think these are dichotomous but I had considered
  what it might look like.

- Rules to follow for a production system that were not followed here
  in order to increase ease-of-deployment:
  - Do not set the instance in a public subnet, rather set it in a private
    subnet.
  - Identify analytics use-cases and have database/read solution based off those
    use-cases. Since I was exploring the data, I wanted an easy data loading
    and reading solution.
  - Separate out analytics database from analysis instance, ie have mongodb on
    its own instance and the jupyter notebook on its own.
  - Lock-down user and db permissions structure on jupyterhub and mongodb.
  - Use SSL for connections over the internet.
  - Dockerize terraform and ansible requirements with 'yelp_analysis' repo.
  - Do not use admin access keys but specific keys for creating infrastructure
  - Do not use public s3 buckets for data & analyses. This was used to circumvent
    the need for credentials.

- There are many places to improve here! Two major areas are just having a more
  robust understanding of linux system administration such that I could understand
  all the permissions details of the db and jupyter installs. The other is a more
  robust understanding of the modeling process. These would be two items I would
  work on and continue to strengthen.

I used these references/github code to help with the deployment:
https://medium.com/@_oleksii_/how-to-install-tune-mongodb-using-ansible-693a40495ca1
https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180
https://github.com/jenkstom/ansible-jupyterhub
