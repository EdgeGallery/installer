/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package init

import (
	"fmt"
	setup "edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

func NewEdgeCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "edge",
		Short: "Install Edge Node",
		Long:  `Command to Install Edge Node only For Example : edgegallery init edge`,
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("Installation of Edge components")
			err := setup.MECSetup("edge")
			if err != nil {
				return err
			}
			return nil
		},
	}
	return cmd
}
