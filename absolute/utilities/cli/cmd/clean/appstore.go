/* Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package clean

import (
	"fmt"

	"edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

func NewAppstoreCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "appstore",
		Short: "Cleanup Appstore",
		Long:  `Cleanup Appstore`,
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("Clean Appstore command execution")
			err := setup.MECReset("appstore")
			if err != nil {
				return err
			}
			return nil
		},
	}
	return cmd
}
