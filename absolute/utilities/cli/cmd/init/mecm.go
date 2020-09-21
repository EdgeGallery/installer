/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package init

import (
	"edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

// allCmd represents the all command
func NewMecmCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "mecm",
		Short: "Command to install MECM Controller",
		Long:  `Command to Install MECM Controller Node  For example:`,
		RunE: func(cmd *cobra.Command, args []string) error {
			err := setup.MECSetup("mecm")
			if err != nil {
				return err
			}
			return nil
		},
	}
	return cmd
}
