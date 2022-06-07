import datetime
import json
import os
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient


def generate_payload(fname):
    datestr = datetime.datetime.now().strftime("%Y_%m_%d")
    outfile = "{}_{}.json".format(datestr, fname)
    with open(outfile, "w") as f:
        json.dump({"time": str(datetime.datetime.now())}, f)
    return outfile


def upload(storage_url, container, fname, connstring=None):
    if connstring is None:
        creds = DefaultAzureCredential()
        service_client = BlobServiceClient(storage_url, credential=creds)
    else:
        service_client = BlobServiceClient.from_connection_string(connstring)

    blob_client = service_client.get_blob_client(container=container, blob=fname)
    with open(fname, "rb") as data:
        blob_client.upload_blob(data)


if __name__ == "__main__":
    url = os.environ.get("STORAGE_URL")
    container_name = os.environ.get("STORAGE_CONTAINER")
    file_base = os.environ.get("FILE_BASENAME")
    connect_string = os.environ.get('CONNECT_STRING')
    print({'url':url,'folder':container_name,'filebase':file_base})
    print("Generating payload.")
    fname = generate_payload(file_base)
    print("Uploading {}".format(fname))
    upload(url, container_name, fname, connect_string)
    print("Upload complete.")
