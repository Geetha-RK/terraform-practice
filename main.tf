# resource "aws_vpc" "my_vpc" {
#   cidr_block           = "10.123.0.0/16"
#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   tags = {
#     Name = "dev"
#   }
# }

# resource "aws_subnet" "my_public_subnet" {
#   vpc_id                  = aws_vpc.my_vpc.id
#   cidr_block              = "10.123.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "us-west-2a"
#   tags = {
#     Name = "dev-public"
#   }

# }

# resource "aws_internet_gateway" "my_internet_gateway" {
#   vpc_id = aws_vpc.my_vpc.id

#   tags = {
#     Name = "dev-igw"
#   }
# }

# resource "aws_route_table" "my_public_route" {
#   vpc_id = aws_vpc.my_vpc.id

#   tags = {
#     Name = "dev-public-route"
#   }
# }

# resource "aws_route" "default_route" {
#   route_table_id         = aws_route_table.my_public_route.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.my_internet_gateway.id
# }
# resource "aws_s3_bucket" "example" {
#   bucket = "my-ravl-bucket2"

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
# }

# --------------------------------
# Create an S3 bucket

#Creates a random hexid
resource "random_id" "random_hex" {
  byte_length = 8
}
# Variable for bucket name in string datatype
variable "bucket_name" {
  type = string
  description = "Test bucket"
  default = "my-demo-test-bucket"
}
variable "tag_map" {
    type = map(string)
    description = "Tag variable for bucket"
    default = {
    Name = "My bucket"
    Environment = "Dev"
    }
}
# Create a s3 resource
resource "aws_s3_bucket" "test_bucket" {
  bucket = format("%s-%s", var.bucket_name, random_id.random_hex.hex)
  tags = var.tag_map
}

#Upload objects to S3 bucket
resource "aws_s3_object" "test_upload_bucket" {
  for_each = fileset("./images", "**") //upload all object in the path mentioned. its a for each loop. for each file in the folder .
  bucket = aws_s3_bucket.test_bucket.id
  key = each.key #name of the object
  source = "${"./images"}/${each.value}" //file in the folder
  etag = filemd5("${"./images"}/${each.value}")
  server_side_encryption = "AES256"
  tags = var.tag_map

}

#KMS Keys and encryption onto S3 bucket - important to keep the content secure - generate kms key to server side encrytion

resource "aws_kms_key" "s3_bucket_kms_key" {
    description = "KMS key for s3 bucket"
    deletion_window_in_days = 7
    tags = {
        name = "KMS Key for S3 bucket"
    }
}
# Creating alias name forthe kms key
resource "aws_kms_alias" "s3_bucket_kms_key_alias" {
    name = "alias/s3_bucket_kms_key_alias"
    target_key_id = aws_kms_key.s3_bucket_kms_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption_with_kms_key" {
  bucket = aws_s3_bucket.test_bucket.id
  
  rule{
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_kms_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}


