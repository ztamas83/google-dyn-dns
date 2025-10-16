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

dotenv.config({ debug: false, quiet: true });

const config = new MikroConf({
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
  return appConfig;
}

export { auth, getAppConfig, AppConfig };
