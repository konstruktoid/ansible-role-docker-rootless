# State
Task: bump Docker/Compose to latest, role version set to v2.5.0 (user decision, supersedes v2.6.0). No git writes.
Done: get_latest_release.sh run (Docker 29.8.2, Compose v5.6.0); defaults/main.yml + README.md synced; README.md:25 version v2.5.0.
Tox run 1: devel FAIL (verify "Verify rootful website" on resoluteroot, 127.0.0.1:8080 connection closed); docker OK; docker-upstream/upstream pending.
Decision (user): test fixes deferred until after this change is merged. Do not edit molecule/ in this change.
Follow-up: re-run tox -e devel to tell flake from Docker 29.8.2 rootful regression; no retries on website checks in molecule/default/verify.yml:539-566.
Release: tag v2.5.0 does not exist yet (latest tag v2.4.0); README.md is the only file carrying the role version.
