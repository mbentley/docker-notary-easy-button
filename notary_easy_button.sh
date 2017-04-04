#!/bin/bash

# set defaults
DELETE_DELEGATION=${DELETE_DELEGATION:-false}
INITIALIZE_REPO=${INITIALIZE_REPO:-false}

# check to see if a cert.pem exists in the current directory
if [ ! -f "cert.pem" ]
then
  echo "ERROR - cert.pem not found (are you in the right directory?)"
  exit 1
fi

# get DTR info
read -r -p "DTR FQDN: " DTR_URL
read -r -p "DTR username: " USERNAME
read -r -s -p "DTR password: " PASSWORD; echo
read -r -p "DTR namespace: " NAMESPACE
read -r -p "DTR repo list (space separated): " REPO_LIST
read -r -p "Role to grant to user (use username if not sure): " ROLE

# get passphrases for notary operation
read -r -s -p "Root passphrase: " NOTARY_ROOT_PASSPHRASE; echo
read -r -s -p "Targets passphrase: " NOTARY_TARGETS_PASSPHRASE; echo
read -r -s -p "Snapshot passphrase: " NOTARY_SNAPSHOT_PASSPHRASE; echo
read -r -s -p "Delegation passphrase: " NOTARY_DELEGATION_PASSPHRASE; echo

# export env vars
export DTR_URL USERNAME PASSWORD NAMESPACE REPO_LIST NOTARY_ROOT_PASSPHRASE NOTARY_TARGETS_PASSPHRASE NOTARY_SNAPSHOT_PASSPHRASE NOTARY_DELEGATION_PASSPHRASE

# set notary options to make code cleaner
export NOTARY_OPTS="-s https://${DTR_URL} -d ${HOME}/.docker/trust --tlscacert ${HOME}/.docker/tls/${DTR_URL}/ca.crt"

# write expect script
cat > /tmp/notary_expect.exp <<EOL
#!/usr/bin/env expect -f
eval spawn notary \$env(NOTARY_PARAMS)
expect "Enter username: "
send "\$env(USERNAME)\r"
expect "Enter password: "
send "\$env(PASSWORD)\r"
expect eof
EOL

# create DTR CA key directory
if [ ! -d "${HOME}"/.docker/tls/"${DTR_URL}" ]
then
  mkdir -p "${HOME}"/.docker/tls/"${DTR_URL}"
fi

# get DTR CA key
curl -sSL https://"${DTR_URL}"/ca > "${HOME}"/.docker/tls/"${DTR_URL}"/ca.crt

# initialize repos
for i in ${REPO_LIST}
do
  if [ "${DELETE_DELEGATION}" = "true" ]
  then
    echo -e "\ndelete local and remote data"
    NOTARY_PARAMS="${NOTARY_OPTS} delete ${DTR_URL}/${NAMESPACE}/${i} --remote" expect /tmp/notary_expect.exp
  fi

  if [ "${INITIALIZE_REPO}" = "true" ]
  then
    echo -e "\ninitialize repo"
    NOTARY_PARAMS="${NOTARY_OPTS} init ${DTR_URL}/${NAMESPACE}/${i}" expect /tmp/notary_expect.exp
  fi

  echo -e "\npublish staged changes"
  NOTARY_PARAMS="${NOTARY_OPTS} publish ${DTR_URL}/${NAMESPACE}/${i}" expect /tmp/notary_expect.exp

  echo -e "\nrotate snapshot key"
  NOTARY_PARAMS="${NOTARY_OPTS} key rotate ${DTR_URL}/${NAMESPACE}/${i} snapshot --server-managed" expect /tmp/notary_expect.exp

  echo -e "\nadd cert to releases role"
  NOTARY_PARAMS="${NOTARY_OPTS} delegation add -p ${DTR_URL}/${NAMESPACE}/${i} targets/releases --all-paths cert.pem" expect /tmp/notary_expect.exp

  echo -e "\nadd cert to ${ROLE} role"
  NOTARY_PARAMS="${NOTARY_OPTS} delegation add -p ${DTR_URL}/${NAMESPACE}/${i} targets/${ROLE} --all-paths cert.pem" expect /tmp/notary_expect.exp

  echo -e "\nlisting delegations"
  # shellcheck disable=SC2086
  notary ${NOTARY_OPTS} delegation list "${DTR_URL}"/"${NAMESPACE}"/"${i}"
done

# cleanup
rm /tmp/notary_expect.exp

# instruct user to import their private key
echo "Make sure to import the private key on the client performing the signing:"
echo "notary -d ~/.docker/trust key import key.pem"
