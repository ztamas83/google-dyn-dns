# Python3 Google Cloud DNS Updater

This utility runs in Google Cloud Functions and allows for the remote update of DNS records from dynamic clients using an API key.

Support for IPv4 at the moment

## Setup

### Create an app key
Open a terminal window and type the following: (Assuming you are on a Mac or Linux machine) 

```
echo "import secrets; print(secrets.token_urlsafe(64))" | python
```

Store this key in GCP Secret Manager with name `apiKey`.
Take note of this key as it will be the key you require to connect to the updater.

### Setup Workload Identity Federation for deployment

https://github.com/google-github-actions/auth/tree/v2/?tab=readme-ov-file#workload-identity-federation-through-a-service-account

#### Assign required permissions for the deployment service account

A working set of permissions are the following - possibly can be truncated more:
```
cloudbuild.builds.get
cloudbuild.builds.list
cloudbuild.operations.get
cloudbuild.operations.list
cloudfunctions.functions.call
cloudfunctions.functions.create
cloudfunctions.functions.delete
cloudfunctions.functions.get
cloudfunctions.functions.update
cloudfunctions.operations.get
cloudfunctions.operations.list
resourcemanager.projects.get
resourcemanager.projects.list
run.jobs.create
run.jobs.delete
run.jobs.get
run.jobs.run
run.jobs.update
run.operations.get
run.operations.list
run.revisions.get
run.revisions.list
run.routes.get
run.routes.list
run.services.create
run.services.delete
run.services.get
run.services.getIamPolicy
run.services.list
run.services.listEffectiveTags
run.services.listTagBindings
run.services.setIamPolicy
run.services.update
run.tasks.get
run.tasks.list
secretmanager.versions.access
```

### Setup github repository variables and secrets

#### Variables:
- GCP_PROJECT -> set to the GCP project name

The deployment uses https://github.com/google-github-actions/auth/, see that page for instructions
#### Secrets:
- GCP_ID_PROVIDER
- GCP_DEPLOY_ACC -> the service account created


## Basic usage
Configure the application using ENV variables, currently one zone/domain is supported.
The environment vars can be updated in the github deploy flow.

The function detects the caller's IP and updates the specified host's A record to that IP address.

Call the function: 
```
curl -X POST <Function URL> -H "Content-Type:application/json" --data '{"host":"example.com."} -H "x-api-key: <api-key>"
```

This call can be added to a CRON job for periodically updating the DNS record.