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
package init

import (
	"fmt"
	setup "edgegallery/cmd/setup"

	"github.com/spf13/cobra"
)

func NewMepCommand() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "mep",
		Short: "Install MEP Node",
		Long:  `Command to Install MEP Node only For Example : edgegallery init mep`,
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("Installation of MEP components")
			err := setup.MECSetup("mep")
			if err != nil {
				return err
			}
			return nil
		},
	}
	return cmd
}
