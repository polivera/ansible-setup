#!/bin/bash

ansible-playbook main.yml -t global --ask-vault-pass
# ansible-playbook global/global.yml

