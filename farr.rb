require './lib/aws-handler'

handler = AwsHandler.new

handler.create_key_if_not_exists()
vpc_id = handler.create_vpc_if_not_exists()
subnet_id = handler.create_subnet_if_not_exists(vpc_id)
sg_id = handler.create_security_group_if_not_exists(vpc_id)
handler.create_instance(sg_id, subnet_id)
