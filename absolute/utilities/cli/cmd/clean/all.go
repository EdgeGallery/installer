/*
*   Copyright 2020 Huawei Technologies Co., Ltd.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
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
