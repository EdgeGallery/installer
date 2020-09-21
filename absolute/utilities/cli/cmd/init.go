/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
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
