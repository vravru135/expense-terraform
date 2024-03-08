vpc_cidr_block = "10.10.0.0/16"
env            = "dev"
tags = {
  company      = "XYZ Co"
  bu_unit      = "Finance"
  project_name = "expense"
}


public_subnets =["10.10.0.0/24" , "10.10.1.0/24"]
web_subnets =["10.10.2.0/24" , "10.10.3.0/24"]
app_subnets =["10.10.4.0/24" , "10.10.5.0/24"]
db_subnets =["10.10.6.0/24" , "10.10.7.0/24"]

azs                    = ["us-east-1a", "us-east-1b"]
account_id             = ""
default_vpc_id         = ""
default_route_table_id = ""
default_vpc_cidr       = ""