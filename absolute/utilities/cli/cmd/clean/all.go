/*######################################################################################
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
 */
package clean

import (
	"fmt"

	setup "edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

// allCmd represents the all command
func NewAllCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "all",
		Short: "Clean Complete MEC",
		Long:  `Clean Complete MEC`,
		RunE: func(cmd *cobra.Command, args []string) error {
		    setupFlag := cmd.Flag("expose-type")
                setupflagoption := setupFlag.Value.String()
                switch setupflagoption {
                case "nodePort":
                    fmt.Println("stop all command execution")
			        err := setup.MECReset("all nodePort")
			        if err != nil {
				        return err
			        }
                    return nil
                case "ingress":
                    fmt.Println("stop all command execution")
			        err := setup.MECReset("all ingress")
			        if err != nil {
				        return err
			        }
                    return nil
                default:
                    fmt.Println("Provide option for flag [--setup :- all | master] or [-s :- all | master]")
                }
			fmt.Println("stop all command execution")
			err := setup.MECReset("all")
			if err != nil {
				return err
			}
			return nil
		},
	}

	cmd.Flags().StringP("expose-type","e","nodePort","MEC deployment options")
	return cmd
}
