/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
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
