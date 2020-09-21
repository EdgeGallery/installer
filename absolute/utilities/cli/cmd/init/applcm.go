/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package init

import (
	setup "edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

func NewAppLcmCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "applcm",
		RunE: func(cmd *cobra.Command, args []string) error {
			err := setup.MECSetup("applcm")
			if err != nil {
				return err
			}
			return nil
		},
	}
	return cmd
}
