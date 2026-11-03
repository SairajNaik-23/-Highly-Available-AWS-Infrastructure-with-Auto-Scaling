# Interview Guide: Highly Available AWS Infrastructure

## 60-second explanation

> "I built a highly available web tier on AWS using Terraform. I created a VPC across two Availability Zones with public and private subnets. The Application Load Balancer sits in the public subnets, and the EC2 instances run in the private subnets, managed by an Auto Scaling Group with a minimum of two instances, one per AZ. The ALB health-checks every instance on /health, and because the ASG uses the ELB health check, any failed instance is replaced automatically. A target tracking policy keeps average CPU at 50% by scaling between 2 and 6 instances. CloudWatch alarms for high CPU, unhealthy hosts and 5xx errors send email alerts through SNS, and Route 53 points a domain to the ALB. I tested it by stressing the CPU to trigger scale-out and by terminating an instance to prove the site stays up."

## Common questions

**Q: What is the difference between high availability and fault tolerance?**
High availability means the system stays up with very little downtime, for example by having instances in two AZs. Fault tolerance means a component can fail with zero impact to users. Here, one instance or even one AZ can fail and the ALB keeps serving from the other.

**Q: Why private subnets for the EC2 instances?**
They don't need to be reached directly. Users go through the ALB. Private subnets plus a security group that only allows the ALB greatly reduce the attack surface. The NAT gateway lets them download packages.

**Q: What's the difference between an ALB and an NLB?**
An ALB works at layer 7 (HTTP/HTTPS) and can route by path or host, do health checks on a URL, and handle TLS. An NLB works at layer 4 (TCP/UDP), has very low latency, and gives static IPs. For a web app, the ALB is the right choice.

**Q: EC2 health check vs ELB health check in an ASG?**
The EC2 health check only knows whether the VM is running. The ELB health check knows whether the **app** actually answers. With `health_check_type = "ELB"`, an instance whose web server crashed is also replaced.

**Q: What is the health check grace period?**
The time (120s here) the ASG waits after launch before checking health, so the boot script has time to install Apache. Without it, new instances would be killed before they were ready.

**Q: Target tracking vs step scaling vs scheduled scaling?**
Target tracking: "keep CPU at 50%", and AWS calculates how many instances to add. Step scaling: you define the steps, for example +1 at 70% and +2 at 90%. Scheduled: scale at fixed times, for example before office hours. Target tracking is the simplest and most common choice.

**Q: How do you update the app without downtime?**
Change the launch template (new AMI or user data) and the ASG **instance refresh** replaces instances gradually while keeping at least 50% healthy. The ALB only sends traffic to healthy ones.

**Q: Why a launch template instead of a launch configuration?**
Launch configurations are deprecated. Launch templates support versioning, IMDSv2 settings, mixed instance types and Spot.

**Q: How do you access the instances without SSH?**
AWS Systems Manager Session Manager. The instance role has `AmazonSSMManagedInstanceCore`, so there's no key pair, no port 22, and every session is logged. My stress test script also uses SSM Run Command.

**Q: What is a Route 53 alias record?**
An AWS-specific record that points to AWS resources such as an ALB. Unlike a CNAME, it works at the zone apex (example.com), queries are free, and it follows the ALB when its IPs change.

**Q: How would you make this production-ready?**
HTTPS with an ACM certificate and an HTTP→HTTPS redirect, AWS WAF on the ALB, one NAT gateway per AZ, remote Terraform state in S3 with DynamoDB locking, and a database such as RDS Multi-AZ if the app needs one.
