docker-notary-easy-button
=========================

Script that makes it easier to create delegations with the notary CLI and a Docker Trusted Registry (DTR)

### Usage

Make sure that your PWD is where your `cert.pem` is from the client bundle you wantto create a delegation for and then run the following command:

```
docker run -it --rm \
  --init \
  -u $(id -u) \
  -e HOME=/notary \
  -v ~/.docker/trust:/notary/.docker/trust \
  -v ~/.docker/tls:/notary/.docker/tls \
  -v ${PWD}:/data:ro \
  -e DELETE_DELEGATION=false \
  -e INITIALIZE_REPO=false \
  mbentley/notary-easy-button
```

There are two environment variables that control some functionality:
  * `DELETE_DELEGATION`
    * Use `DELETE_DELEGATION=true` if you have previous signatures or the repo has previously been initialzed and you want to remove all data.
  * `INITIALIZE_REPO`
    * Use `INITIALIZE_REPO=true` if the delegation for the repository has just been deleted or if the repository has never been initialized previously.

It will prompt you for information and output the data.  Example successful delegation creation:

```
docker run -it --rm \
  --init \
  -u $(id -u) \
  -e HOME=/notary \
  -v ~/.docker/trust:/notary/.docker/trust \
  -v ~/.docker/tls:/notary/.docker/tls \
  -v ${PWD}:/data:ro \
  -e DELETE_DELEGATION=false \
  -e INITIALIZE_REPO=false \
  mbentley/notary-easy-button
DTR FQDN: dtr.demo.dckr.org
DTR username: demo
DTR password:
DTR namespace: demo
DTR repo list (space separated): signtest
Role to grant to user (use username if not sure): foo
Root passphrase:
Targets passphrase:
Snapshot passphrase:
Delegation passphrase:

publish staged changes
spawn notary -s https://dtr.demo.dckr.org -d /notary/.docker/trust --tlscacert /notary/.docker/tls/dtr.demo.dckr.org/ca.crt publish dtr.demo.dckr.org/demo/signtest
Pushing changes to dtr.demo.dckr.org/demo/signtest
Enter username: demo
Enter password:
Successfully published changes for repository dtr.demo.dckr.org/demo/signtest

rotate snapshot key
spawn notary -s https://dtr.demo.dckr.org -d /notary/.docker/trust --tlscacert /notary/.docker/tls/dtr.demo.dckr.org/ca.crt key rotate dtr.demo.dckr.org/demo/signtest snapshot --server-managed
Enter username: demo
Enter password:
Successfully rotated snapshot key for repository dtr.demo.dckr.org/demo/signtest

add cert to releases role
spawn notary -s https://dtr.demo.dckr.org -d /notary/.docker/trust --tlscacert /notary/.docker/tls/dtr.demo.dckr.org/ca.crt delegation add -p dtr.demo.dckr.org/demo/signtest targets/releases --all-paths cert.pem

Addition of delegation role targets/releases with keys [185b14b1e4e922363d84a39b5204edf261475da2f75ee2a2283c3283786fbcde], with paths ["" <all paths>], to repository "dtr.demo.dckr.org/demo/signtest" staged for next publish.

Auto-publishing changes to dtr.demo.dckr.org/demo/signtest
Enter username: demo
Enter password:
Successfully published changes for repository dtr.demo.dckr.org/demo/signtest

add cert to foo role
spawn notary -s https://dtr.demo.dckr.org -d /notary/.docker/trust --tlscacert /notary/.docker/tls/dtr.demo.dckr.org/ca.crt delegation add -p dtr.demo.dckr.org/demo/signtest targets/foo --all-paths cert.pem

Addition of delegation role targets/foo with keys [185b14b1e4e922363d84a39b5204edf261475da2f75ee2a2283c3283786fbcde], with paths ["" <all paths>], to repository "dtr.demo.dckr.org/demo/signtest" staged for next publish.

Auto-publishing changes to dtr.demo.dckr.org/demo/signtest
Enter username: demo
Enter password:
Successfully published changes for repository dtr.demo.dckr.org/demo/signtest

listing delegations

ROLE                PATHS             KEY IDS                                                             THRESHOLD
----                -----             -------                                                             ---------
targets/demo        "" <all paths>    185b14b1e4e922363d84a39b5204edf261475da2f75ee2a2283c3283786fbcde    1
targets/foo         "" <all paths>    185b14b1e4e922363d84a39b5204edf261475da2f75ee2a2283c3283786fbcde    1
targets/releases    "" <all paths>    185b14b1e4e922363d84a39b5204edf261475da2f75ee2a2283c3283786fbcde    1

Make sure to import the private key on the client performing the signing:
notary -d ~/.docker/trust key import key.pem
```
