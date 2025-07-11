import azure.functions as func
import logging
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient

def main(mytimer: func.TimerRequest) -> None:
    """
    Azure Function to shutdown VMSS instances at scheduled time
    Default schedule: 19:00 UTC (7:00 PM)
    """
    utc_timestamp = mytimer.utc_timestamp.replace(
        tzinfo=None
    ).isoformat()
    
    if mytimer.past_due:
        logging.info('The timer is past due!')
    
    logging.info('VMSS shutdown timer triggered at %s', utc_timestamp)
    
    try:
        # Get environment variables
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        resource_group_name = os.environ.get('RG_NAME')
        vmss_name = os.environ.get('VMSS_NAME')
        
        if not all([subscription_id, resource_group_name, vmss_name]):
            logging.error("Missing required environment variables")
            logging.error(f"AZURE_SUBSCRIPTION_ID: {subscription_id}")
            logging.error(f"RG_NAME: {resource_group_name}")
            logging.error(f"VMSS_NAME: {vmss_name}")
            return
        
        # Authenticate using managed identity
        credential = DefaultAzureCredential()
        compute_client = ComputeManagementClient(credential, subscription_id)
        
        # Get VMSS instances
        logging.info(f"Getting instances for VMSS: {vmss_name}")
        vmss_instances = compute_client.virtual_machine_scale_set_vms.list(
            resource_group_name, vmss_name
        )
        
        instance_ids = [instance.instance_id for instance in vmss_instances]
        
        if not instance_ids:
            logging.info("No VMSS instances found to shutdown")
            return
        
        logging.info(f"Found {len(instance_ids)} instances to shutdown: {instance_ids}")
        
        # Shutdown all instances
        for instance_id in instance_ids:
            logging.info(f"Shutting down VMSS instance: {instance_id}")
            compute_client.virtual_machine_scale_set_vms.begin_deallocate(
                resource_group_name, vmss_name, instance_id
            )
        
        logging.info(f"Successfully initiated shutdown for {len(instance_ids)} VMSS instances")
        
    except Exception as e:
        logging.error(f"Error shutting down VMSS: {str(e)}")
        raise
