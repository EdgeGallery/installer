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
	initcmds "edgegallery/cmd/init"
	"github.com/spf13/cobra"
)

// initCmd represents the init command
var initCmd = &cobra.Command{
	Use:   "init",
	Short: "To setup the MEC Environment",
	Long: `To setup the MEC Environment edgegallery init command has following options:
	"all"  : To Install the complete MEC Environment,
	"mecm" : To Install the MECM Component, 
	"mep"  : To Install the MEP Component.`,
}

func init() {

	//Adding all subcommands of init subcommand
	//edgegallery init all
	initCmd.AddCommand(initcmds.NewAllCommand())
	//edgegallery init edge
	initCmd.AddCommand(initcmds.NewEdgeCommand())
	//edgegallery init infra
	initCmd.AddCommand(initcmds.NewInfraCommand())
        //edgegallery init applcm
	initCmd.AddCommand(initcmds.NewAppLcmCommand())
	//edgegallery init controller
	initCmd.AddCommand(initcmds.NewControllerCommand())
	//edgegallery init mep
	initCmd.AddCommand(initcmds.NewMepCommand())
	//edgegallery init mecm
	initCmd.AddCommand(initcmds.NewMecmCommand())
	//edgegallery init appstore
	initCmd.AddCommand(initcmds.NewAppstoreCommand())
	//edgegallery init developer
	initCmd.AddCommand(initcmds.NewDeveloperCommand())
	//edgegallery init user_mgmt
	initCmd.AddCommand(initcmds.NewUserMgmtCommand())
	//edgegallery init service_center
	initCmd.AddCommand(initcmds.NewServiceCenterCommand())
	//edgegallery init tool_chain
	initCmd.AddCommand(initcmds.NewToolChainCommand())
	//Add init subcommand to root command.
	rootCmd.AddCommand(initCmd)
}
