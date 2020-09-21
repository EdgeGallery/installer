/*
 Copyright (c) 2019 Huawei Tech and others.

 All rights reserved. This program and the accompanying materials
 are made available under the terms of the Apache License, Version 2.0
 which accompanies this distribution, and is available at
 http://www.apache.org/licenses/LICENSE-2.0
*/
package setup

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"
)

//Command defines commands to be executed and captures std out and std error
type Command struct {
	Cmd    *exec.Cmd
	StdOut []byte
	StdErr []byte
}

func (cm Command) GetStdOutput() string {
	if len(cm.StdOut) != 0 {
		return strings.TrimRight(string(cm.StdOut), "\n")
	}
	return ""
}

//GetStdErr gets StdErr field
func (cm Command) GetStdErr() string {
	if len(cm.StdErr) != 0 {
		return strings.TrimRight(string(cm.StdErr), "\n")
	}
	return ""
}

//It helps in the commands where it takes some time for execution.
func (cm Command) ExecuteCmdShowOutput() error {
	var stdoutBuf, stderrBuf bytes.Buffer
	stdoutIn, _ := cm.Cmd.StdoutPipe()
	stderrIn, _ := cm.Cmd.StderrPipe()

	var errStdout, errStderr error
	stdout := io.MultiWriter(os.Stdout, &stdoutBuf)
	stderr := io.MultiWriter(os.Stderr, &stderrBuf)
	err := cm.Cmd.Start()
	if err != nil {
		return fmt.Errorf("failed to start '%s' because of error : %s", strings.Join(cm.Cmd.Args, " "), err.Error())
	}

	var wg sync.WaitGroup
	wg.Add(1)

	go func() {
		_, errStdout = io.Copy(stdout, stdoutIn)
		wg.Done()
	}()

	_, errStderr = io.Copy(stderr, stderrIn)
	wg.Wait()

	err = cm.Cmd.Wait()
	if err != nil {
		return fmt.Errorf("failed to run '%s' because of error : %s", strings.Join(cm.Cmd.Args, " "), err.Error())
	}
	if errStdout != nil || errStderr != nil {
		return fmt.Errorf("failed to capture stdout or stderr")
	}

	cm.StdOut, cm.StdErr = stdoutBuf.Bytes(), stderrBuf.Bytes()
	return nil
}

// It returns an error if the command outputs anything on the stderr.
func runCommandInShell(command string) (string, error) {
	cmd := &Command{Cmd: exec.Command("sh", "-c", command)}
	err := cmd.ExecuteCmdShowOutput()
	if err != nil {
		return "", err
	}
	errout := cmd.GetStdErr()
	if errout != "" {
		return "", fmt.Errorf("%s", errout)
	}
	return cmd.GetStdOutput(), nil
}
