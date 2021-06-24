#
#   Copyright 2021 Huawei Technologies Co., Ltd.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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
            daemon_json='/etc/docker/daemon.json')
            print('done')
            sys.exit(0) # successful update
        else:
            print('Usage: <list of insecure registry entries>')
            sys.exit(1) # Invalid args
    except Exception as e:
        print(e)
        sys.exit(2) # Error while processing the file
