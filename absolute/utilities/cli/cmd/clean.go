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
package cmd

import (
	cleancmds "edgegallery/cmd/clean"

	"github.com/spf13/cobra"
)

// cleanCmd represents the clean command
var cleanCmd = &cobra.Command{
	Use:   "stop",
	Short: "To Reset the MEC Environment",
	Long: `To Reset the MEC Environment, it provides multiple options 
	Options are : 
	edgegallery clean all .
	edgegallery clean mecm
	edgegallery clean mep`,
}

func init() {
	cleanCmd.AddCommand(cleancmds.NewAllCommand())
        cleanCmd.AddCommand(cleancmds.NewEdgeCommand())
	cleanCmd.AddCommand(cleancmds.NewInfraCommand())
        cleanCmd.AddCommand(cleancmds.NewAppLcmCommand())
	cleanCmd.AddCommand(cleancmds.NewControllerCommand())
	cleanCmd.AddCommand(cleancmds.NewMecmCommand())
	cleanCmd.AddCommand(cleancmds.NewMepCommand())
	cleanCmd.AddCommand(cleancmds.NewAppstoreCommand())
	cleanCmd.AddCommand(cleancmds.NewDeveloperCommand())
	cleanCmd.AddCommand(cleancmds.NewUserMgmtCommand())
	cleanCmd.AddCommand(cleancmds.NewServiceCenterCommand())
	cleanCmd.AddCommand(cleancmds.NewToolChainCommand())

	rootCmd.AddCommand(cleanCmd)
}
