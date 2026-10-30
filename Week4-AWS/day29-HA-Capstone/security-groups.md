# Day 29 Security Group Rules

## alb-sg
Inbound:
- TCP 80 from 0.0.0.0/0

## app-sg
Inbound:
- TCP 80 from alb-sg only

## db-sg
Inbound:
- TCP 5432 from app-sg only

Traffic flow:
Internet -> ALB -> EC2 App -> RDS
