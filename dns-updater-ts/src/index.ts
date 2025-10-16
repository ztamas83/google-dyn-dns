import { Request, Response } from "express";
import { DNS } from "@google-cloud/dns";
import { AppConfig, auth, getAppConfig } from "./config";

async function updateRecord(
  host: string,
  caller_ip: string,
  gcpProject: string,
  zoneName: string
): Promise<void> {
  const dns = new DNS({
    projectId: gcpProject,
  });

  const zone = dns.zone(zoneName);

  const [records] = await zone.getRecords({ name: host });
  console.log("Fetched records:", records);
  const aRecord = records.find(
    (r) => r.type === "A" && r.metadata.name === host
  );

  console.log("Current A record:", aRecord);

  if (aRecord && aRecord!.data!.includes(caller_ip)) {
    console.log(`IP for ${host} is already ${caller_ip}`);
    return;
  }

  try {
    if (!aRecord) {
      await zone.createChange({
        add: [zone.record("A", { name: host, data: [caller_ip], ttl: 300 })],
      });
    } else {
      const updateUrl = `https://dns.googleapis.com/dns/v1/projects/${gcpProject}/managedZones/${zone.name}/rrsets/${host}/A`;

      console.log("Updating record at:", updateUrl);

      const data = { ttl: 300, rrdatas: [caller_ip] };
      auth.isGCE;
      await auth.fetch(updateUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });
    }
  } catch (error) {
    console.error("Error updating record via fetch:", error);
    throw error;
  }

  console.log(`Updated IP for ${host} to ${caller_ip}`);
}

export async function httpFunction(req: Request, res: Response): Promise<void> {
  console.log(
    "Received request method, URL, body, query",
    req.method,
    req.url,
    req.body,
    req.query
  );

  if (req.url.split("?")[0] !== "/") {
    res.status(404).send("Not found");
    return;
  }

  if (req.method !== "POST" && req.method !== "GET") {
    res.status(405).send("Invalid method");
  }

  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith("Basic ")) {
    res.status(401).send("Unauthorized");
  }

  // console.log("Authorization header received", auth);

  const appConfig = await getAppConfig();

  // console.log("Using configuration:", appConfig);

  const gcpProject = appConfig.gcp.projectId;

  if (!gcpProject) {
    console.error("Missing required environment variables");
    process.exit(1);
  }

  const decodedAuth = Buffer.from(auth!.substring(6), "base64").toString(
    "utf-8"
  );
  // console.log("Decoded auth:", decodedAuth);
  const [reqUser, reqPass] = decodedAuth.split(":");

  if (reqUser !== appConfig.httpAuth.username) {
    console.error("Unauthorized access attempt with user:", reqUser);
    res.status(403).send("Unauthorized");
    return;
  }

  if (reqPass !== appConfig.httpAuth.password) {
    console.error("Unauthorized access attempt with password:", reqPass);
    res.status(403).send("Unauthorized");
    return;
  }

  const host = (
    req.method === "POST" ? req.body.host : req.query.host
  ) as string;

  if (!host) {
    res.status(400).send("Missing host parameter");
    return;
  }

  const fqdn = `${host}.${appConfig.dns.domain}.`;
  console.log("Updating DNS for FQDN:", fqdn);

  try {
    const publicIp = req.headers["x-forwarded-for"];
    console.log("Detected public IP:", publicIp);
    if (!publicIp || Array.isArray(publicIp)) {
      throw new Error("Could not determine public IP");
    }
    await updateRecord(
      fqdn,
      publicIp,
      appConfig.gcp.projectId!,
      appConfig.dns.zone!
    );

    res.status(200).send(`DNS record for ${fqdn} set to ${publicIp}`);
  } catch (error) {
    console.error("Error updating DNS record", error);
    res.status(500).send("Error updating DNS record");
  }
}
