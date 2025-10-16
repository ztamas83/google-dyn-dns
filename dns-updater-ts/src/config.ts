import { MikroConf } from "mikroconf";
import { GoogleAuth } from "google-auth-library";
import dotenv from "dotenv";

interface AppConfig {
  gcp: {
    projectId: string | undefined;
  };
  dns: {
    zone: string;
    domain: string;
    ttl: number;
  };
  httpAuth: {
    username: string | undefined;
    password: string | undefined;
  };
  debug: boolean;
}

const auth = new GoogleAuth({
  scopes: "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
});

// async function getProjectId(): Promise<string | undefined> {
//   // check to see if this code can access a metadata server
//   const isAvailable = await metadata.isAvailable();
//   console.log(`Is available: ${isAvailable}`);

//   // Instance and Project level metadata will only be available if
//   // running inside of a Google Cloud compute environment such as
//   // Cloud Functions, App Engine, Kubernetes Engine, or Compute Engine.
//   // To learn more about the differences between instance and project
//   // level metadata, see:
//   // https://cloud.google.com/compute/docs/storing-retrieving-metadata#project-instance-metadata

//   return isAvailable ? await metadata.project("project-id") : undefined;
// }

dotenv.config({ debug: true, quiet: true });

const config = new MikroConf({
  configFilePath: "config.json", // Load from this file if it exists
  options: [
    { path: "gcp.projectId", defaultValue: "" },
    { path: "dns.zone", defaultValue: process.env.DNS_ZONE },
    { path: "dns.domain", defaultValue: process.env.DNS_DOMAIN },
    { path: "dns.ttl", defaultValue: 3600 },
    { path: "httpAuth.username", defaultValue: process.env.API_USER },
    { path: "httpAuth.password", defaultValue: process.env.API_PASSWORD },
    {
      path: "debug",
      defaultValue: process.env.DEBUG === "true" ? true : false,
    }, // Will use the default value
  ],
});

const appConfig = config.get<AppConfig>();

async function getAppConfig(): Promise<AppConfig> {
  const projectId = await auth.getProjectId();
  console.log("Detected GCP Project ID:", projectId);
  config.setValue("gcp.projectId", projectId);

  console.log(
    "After async operation, configuration is:",
    config.get<AppConfig>()
  );
  return appConfig;
}

export { auth, getAppConfig, AppConfig };
