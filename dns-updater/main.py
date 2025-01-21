# The main python file that does the work
import google.cloud.logging
import logging
import time
import urllib.request
import google.auth
from google.cloud import dns
from google.oauth2 import service_account
from ipaddress import ip_address, IPv4Address, IPv6Address
import json
import functions_framework
import config
from flask import Request
from werkzeug.datastructures import Authorization
import os

# app = flask.Flask(__name__)
# app.config["DEBUG"] = True

# Grab our configuration
cfg = config.cfg

# Configure the client & zone
if len(cfg.gcpAuthKeyJsonFile) == 0:
    credentials, project = google.auth.default(
        scopes="https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    )
else:
    credentials = service_account.Credentials.from_service_account_file(
        cfg.gcpAuthKeyJsonFile
    )

log_client = google.cloud.logging.Client()
log_client.get_default_handler()
log_client.setup_logging()

client = dns.Client(project=cfg.gcpProject, credentials=credentials)
zone = client.zone(cfg.gcpDnsZoneName, cfg.gcpDnsDomain)

records = ""
changes = zone.changes()


def not_found(e):
    logging.error("The resource could not be found. %s", e)
    return "The resource could not be found", 404


def bad_request(e):
    logging.warning("Incorrect parameters", e)
    return "Invalid request", 400


def unauthorized(e):
    logging.warning("You are not authorized to access this resource. %s", e)
    return "You are not authorized to access this resource.", 401


@functions_framework.http
def main(request: Request):
    a_record_found = False
    aaaa_record_found = False
    a_record_changed = False
    aaaa_record_changed = False
    ret_val = ""

    if request.method not in ["POST", "GET"]:
        return "Invalid method", 405

    caller_ip = request.headers.get("X-Forwarded-For")
    logging.info(f"Update request started. Caller: {caller_ip}")

    if request.authorization.type != "basic":
        return bad_request(request.headers)

    # Check the key
    if not (check_key(request.authorization)):
        return unauthorized(f"Invalid auth params: {request.authorization.parameters}")

    host = cfg.gcpDnsDomain
    if request.method == "POST":
        request_json = request.get_json(silent=True)

        logging.info(f"Request args: {request_json}")
        # Assign our parameters
        host = request_json["host"] if request_json else None

    if not (validIPv4Address(caller_ip)):
        logging.warning(f"Cannot determine caller IP or wrong format {caller_ip}")
        caller_ip = ""

    # Check we have the required parameters
    if (host is None) or (not caller_ip):
        return bad_request('Missing required parameters. "host" and "ip" are required.')

    # Get a list of the current records
    records = get_records()

    # Check for matching records
    for record in records:
        if record.name == host and record.record_type == "A":
            a_record_found = True
            for data in record.rrdatas:
                if test_for_record_change(data, caller_ip):
                    try:
                        url = f"https://dns.googleapis.com/dns/v1/projects/{project}/managedZones/{zone.name}/rrsets/{host}/A"

                        logging.info("Calling DNS update", extra={"url": url})
                        req = urllib.request.Request(url, method="PATCH")
                        req.data = json.dumps(
                            {"ttl": 300, "rrdatas": [caller_ip]}
                        ).encode("utf-8")
                        req.add_header("Authorization", f"Bearer {credentials.token}")
                        req.add_header("Content-Type", "application/json")

                        res = urllib.request.urlopen(req)

                        with urllib.request.urlopen(req) as res:
                            # Check the result code
                            result_code = res.getcode()
                            if result_code == 200:
                                ret_val += "IPv4 changed successfully.\n"
                            else:
                                logging.error(res)
                                ret_val += f"IPv4 update failed with status code: {result_code}\n"
                    except urllib.error.HTTPError as error:
                        logging.error(error)
                        ret_val += f"IPv4 update failed with error: {error.code} - {error.reason}\n"
                else:
                    ret_val += "IPv4 record up to date.\n"
        # if record.name == host and record.record_type == 'AAAA' and ipv6:
        #     aaaa_record_found = True
        #     for data in record.rrdatas:
        #         if test_for_record_change(data, ipv6):
        #             add_to_change_set(record, 'delete')
        #             add_to_change_set(create_record_set(host, record.record_type, ipv6), 'create')
        #             aaaa_record_changed = True
        #             ret_val += "IPv6 changed successful.\n"
        #         else:
        #             ret_val += "IPv6 Record up to date.\n"

    if not (a_record_found or aaaa_record_found):
        return not_found(host)

    return ret_val


def check_key(auth: Authorization):
    if not auth:
        logging.error("Missing api key")
        return False

    else:
        try:
            if (
                auth.parameters["username"] == cfg.apiUser
                and auth.parameters["password"] == cfg.apiKey
            ):
                logging.info("Key received from client is correct.")
                return True
            else:
                logging.error("Authentication parameters are incorrect.")
                return False
        except Exception as e:
            logging.error(f"Error decoding basic auth key: {e}")
            return False


def validIPv4Address(ip):
    try:
        return True if ip and type(ip_address(ip)) is IPv4Address else False
    except ValueError:
        return False


def validIPv6Address(ip):
    try:
        return True if type(ip_address(ip)) is IPv6Address else False
    except ValueError:
        return False


def get_records(client=client, zone=zone):
    # Get the records in batches
    return zone.list_resource_record_sets(
        max_results=100, page_token=None, client=client
    )


def test_for_record_change(old_ip, new_ip):
    logging.info("Existing IP is {}".format(old_ip))
    logging.info("New IP is {}".format(new_ip))
    if old_ip != new_ip:
        logging.info("IP addresses do no match. Update required.")
        return True
    else:
        logging.info("IP addresses match. No update required.")
        return False


def create_record_set(host, record_type, ip):
    record_set = zone.resource_record_set(host, record_type, cfg.ttl, [ip])
    return record_set


def add_to_change_set(record_set, atype):
    if atype == "delete":
        return changes.delete_record_set(record_set)
    else:
        return changes.add_record_set(record_set)


def execute_change_set(changes):
    logging.info("Change set executed")
    changes.create()
    while changes.status != "done":
        logging.info(
            "Waiting for changes to complete. Change status is {}".format(
                changes.status
            )
        )
        time.sleep(20)
        changes.reload()


# app.run()
