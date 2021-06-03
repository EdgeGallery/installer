
import json
import os
import sys

def check_and_update_docker_json(list_of_entries=[],
    daemon_json="/etc/docker/daemon.json"):
    try:
        daemon_json_obj = {}

        if not os.path.exists(daemon_json):
            with open(daemon_json, "wt") as fh:
                fh.write(json.dumps(daemon_json_obj))

        with open(daemon_json, "rt") as fh:
            daemon_json_obj = json.load(fh)

            if 'insecure-registries' not in daemon_json_obj.keys():
                daemon_json_obj['insecure-registries'] = []

            for entry in list_of_entries:
                try:
                    if daemon_json_obj['insecure-registries'].index(entry):
                        pass
                except:
                    daemon_json_obj['insecure-registries'].append(entry)

            with open(daemon_json, "wt") as fh:
                fh.write(json.dumps(daemon_json_obj))
    except:
        print("Unexpected error:", sys.exc_info())
        raise

if __name__ == "__main__":
    try:
        if len(sys.argv) > 1:
            check_and_update_docker_json(list_of_entries=sys.argv[1:],
            daemon_json='./daemon.json')
            print('done')
            sys.exit(0) # successful update
        else:
            print('Usage: <list of insecure registry entries>')
            sys.exit(1) # Invalid args
    except:
        sys.exit(2) # Error while processing the file
