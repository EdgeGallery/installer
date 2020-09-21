/* Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package setup

import (
	"fmt"
)

func MECSetup(component string) error {
	strMECSetup := fmt.Sprintf("bash one_click_deploy.sh -i %s", component)

	stdout, err := runCommandInShell(strMECSetup)
	if err != nil {
		return err
	}
	fmt.Println(stdout)
	return nil
}

func MECReset(component string) error {
	strMECReset := fmt.Sprintf("bash one_click_deploy.sh -r %s", component)

	stdout, err := runCommandInShell(strMECReset)
	if err != nil {
		return err
	}
	fmt.Println(stdout)
	return nil
}
