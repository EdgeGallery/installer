import json
import os 
import sys

def aio_mode():
  harbor=open('/tmp/harborip','r')
  harbor_cont=harbor.read()
  harbor.close()

  harbor_ips=[]
  for each in harbor_cont.splitlines():
    harbor_ips.append(each)

  harborip=harbor_ips[0]

  if os.path.exists('/etc/docker/daemon.json'):
    f=open('/etc/docker/daemon.json','r')
    dat=json.load(f)
    if "insecure-registries" in dat:
      if harborip in dat['insecure-registries'] and len(dat['insecure-registries']) == 1:
        print("present")
      else:
        print("not present")
    else: 
      print("not present")
  else:
    print('Path does not exist')


def muno_mode():
  harbor=open('/tmp/harborip','r')
  harbor_cont=harbor.read()
  harbor.close()

  harbor_ips=[]
  for each in harbor_cont.splitlines():
    harbor_ips.append(each)

  harborip=harbor_ips[0]

  private=open('/tmp/private_registryip','r')
  private_registry=private.read()
  private.close()

  private_registry_ips=[]
  for each in private_registry.splitlines():
    private_registry_ips.append(each)

  private_registry_ip=private_registry_ips[0]

  if os.path.exists('/etc/docker/daemon.json'):
    f=open('/etc/docker/daemon.json','r')
    data=json.load(f)
    if 'insecure-registries' in data:
      if harborip in data['insecure-registries'] and private_registry_ip in data['insecure-registries'] and len(data['insecure-registries']) == 2:
        print("present")
      else:
        print("not present")
    else: 
      print("not present")
  else:
    print('Path does not exist')


if len(sys.argv) != 2:
  print("run this script with 1 argument - aio/muno")
else:
  if sys.argv[1] == "aio":
    aio_mode()
  elif sys.argv[1] == "muno":
    muno_mode()
  else:
    print("run with an argument - aio/muno")

