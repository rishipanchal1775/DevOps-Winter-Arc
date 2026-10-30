# Day 29 — Resource Plan

Region: us-east-1

## Existing resources to inspect
- Day 27 VPC:
- Public subnet AZ-A:
- Public subnet AZ-B:
- Private subnet AZ-A:
- Private subnet AZ-B:
- Internet Gateway:
- NAT Gateway:
- Day 26 RDS:
- Day 25 Nginx bootstrap:

## Day 29 planned resources
- ALB: day29-alb
- Target group: day29-app-tg
- Launch template: day29-app-template
- Auto Scaling Group: day29-app-asg
- Security groups: alb-sg, app-sg, db-sg

## Cost decision
- Floci/local simulation: preferred
- Real AWS resources: only if cost has been checked
- Cleanup window:
