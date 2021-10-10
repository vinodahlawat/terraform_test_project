data "aws_ami" "server_ami" {
    most_recent = true
    owners = ["431337925835"]
    filter {
        name = "name"
        values = ["ubunut"]
    }
}

resource "random_id" "test_node_id" {
    byte_length = 2
    count = var.instance_count
 }
resource "aws_key_pair" "test_keypair" {
    key_name = var.key_name
    public_key = file(var.public_key_path)
}

 resource "aws_instance" "test_node" {
     count = var.instance_count
     instance_type = var.instance_type 
     ami = data.aws_ami.server_ami.id

     tags = {
         Name = "test_node-${random_id.test_node_id[count.index].dec}"
     }
 
key_name = aws_key_pair.test_keypair.id   
vpc_security_group_ids = [var.test_sg]
subnet_id  = var.test_subnet[count.index]
user_data = templatefile(var.user_data_path,
{
    nodename = "test-node${random_id.test_node_id[count.index].dec}"
    db_endpoint = var.db_endpoint
    dbuser = var.dbuser
    dbpass = var.dbpassword
    dbname = var.dbname
}
)
root_block_device {
volume_size = var.vol_size
}
 }

 resource "aws_lb_target_group_attachment" "test_tg_attach" {
     count = var.instance_count
     target_group_arn = var.lb_target_group_arn
     target_id = aws_instance.test_node[count.index].id
     port = 8000
 }
