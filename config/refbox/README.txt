Copy the entire config/refbox directory from your existing rcll-get-started project into this directory. Preserve all subdirectories and YAML files. At minimum this stack expects:
  challenges/thopen/nav_hard.yaml
  comm/raikmitl_comm.yaml

In this copied project only, update mongodb/default_mongodb.yaml and mongodb/enable_mongodb.yaml so hostport uses the Compose service hostname `mongodb` (or `mongodb:27017`, according to the config format supported by your RefBox build). Do not modify the original VM's config.

Also replace VM-only peer IP addresses in comm/raikmitl_comm.yaml with addresses appropriate for the laptop/robot network.
