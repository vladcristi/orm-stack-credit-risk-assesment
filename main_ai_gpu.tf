provider "oci" {}

data "oci_core_images" "gpu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "BM.GPU4.8"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "launch_mode"
    values = ["NATIVE"]
  }
  filter {
    name = "display_name"
    values = ["\\w*GPU\\w*"]
    regex = true
  }
}

data "template_file" "script" {
	template = file("${path.module}/jupyter_notebooks/1_mortcudf_data_prep.ipynb")
	vars = {
		bucket_namespace = var.bucket_namespace
	}

}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = true
  part {
    filename     = "cloudinit.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/cloudinit.sh")
  }
}


resource "oci_core_instance" "this" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "DISABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Oracle Java Management Service"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "OS Management Service Agent"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "OS Management Hub Agent"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Management Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Custom Logs Monitoring"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute RDMA GPU Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Run Command"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute HPC RDMA Auto-Configuration"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Compute HPC RDMA Authentication"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Cloud Guard Workload Protection"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Block Volume Management"
		}
		plugins_config {
			desired_state = "DISABLED"
			name = "Bastion"
		}
	}
	availability_config {
		is_live_migration_preferred = "false"
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = var.ad
	compartment_id = var.compartment_ocid
	create_vnic_details {
		assign_ipv6ip = "false"
		assign_private_dns_record = "true"
		assign_public_ip = "true"
		subnet_id = var.subnet_id
	}
	display_name = var.vm_display_name
	metadata = {
		ssh_authorized_keys = local.bundled_ssh_public_keys
		user_data           = data.cloudinit_config.config.rendered
	}
	shape = "BM.GPU4.8"
	source_details {
		boot_volume_size_in_gbs = "1500"
		boot_volume_vpus_per_gb = "10"
		#source_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaf7f2j6ehj4irpvucrxenh6y5cyxhyzycio4mu2cdrf5mfsy4wwhq"
		source_id = data.oci_core_images.gpu_images.images[0].id
		source_type = "image"
	}
	freeform_tags = {"GPU_TAG"= "A100-8"}

	
}

resource "time_sleep" "wait_10_minutes_for_BM_to_be_available_for_ssh" {
  depends_on = [oci_core_instance.this]

  create_duration = "600s"
}

resource "null_resource" "this" {
	depends_on = [ time_sleep.wait_10_minutes_for_BM_to_be_available_for_ssh ]
	provisioner "file" {
		source      = "jupyter_notebooks/1_mortcudf_data_prep.ipynb"
		destination = "/home/opc/1_mortcudf_data_prep.ipynb"
 	}
	provisioner "file" {
		source      = "jupyter_notebooks/2_mortcudf_XGB_Pytorch.ipynb"
		destination = "/home/opc/2_mortcudf_XGB_Pytorch.ipynb"
 	}
	provisioner "file" {
		source      = "jupyter_notebooks/3_mortcudf_captum-2.ipynb"
		destination = "/home/opc/3_mortcudf_captum-2.ipynb"
 	}
	provisioner "file" {
		source      = "jupyter_notebooks/4_mortcudf_shapley_viz-2.ipynb"
		destination = "/home/opc/4_mortcudf_shapley_viz-2.ipynb"
 	}
	provisioner "file" {
		source      = "jupyter_notebooks/clfmodel.py"
		destination = "/home/opc/clfmodel.py"
 	}

	provisioner "file" {
		source      = "cloudinit.sh"
		destination = "/home/opc/cloudinit.sh"
 	}

	connection {
		type    	= "ssh"
		user     	= "opc"
		private_key = tls_private_key.stack_key.private_key_openssh
		host    	= oci_core_instance.this.public_ip
	}
	
}

resource "oci_objectstorage_bucket" "test_bucket" {
    compartment_id = var.compartment_ocid
    name = "mortgage-bucket-dataset"
    namespace = var.bucket_namespace
}