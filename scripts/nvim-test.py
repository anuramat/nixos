#!/usr/bin/env python3
"""
Test script for running Neovim in a proper pseudo-terminal environment.
This allows Claude Code to test Neovim configurations properly.
"""

import pty
import subprocess
import sys
import os
import time

def run_nvim_in_pty(commands=None):
    """Run nvim in a pseudo-terminal with optional commands."""
    if commands is None:
        commands = [
            ':echo "Neovim test successful"',
            ':sleep 1',
            ':quit'
        ]
    
    # Set up environment
    env = os.environ.copy()
    env.update({
        'TERM': 'xterm-256color',
        'COLUMNS': '120',
        'LINES': '30'
    })
    
    def run():
        # Build command string
        cmd_string = ' | '.join(f'echo "{cmd}"' for cmd in commands)
        full_cmd = f'({cmd_string}) | nvim -'
        
        try:
            result = subprocess.run(
                ['nvim'] + ['-c ' + cmd for cmd in commands],
                env=env,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired:
            return "", "Timeout expired", 1
    
    # Run in pseudo-terminal
    master, slave = pty.openpty()
    try:
        pid = os.fork()
        if pid == 0:  # Child process
            os.close(master)
            os.dup2(slave, 0)  # stdin
            os.dup2(slave, 1)  # stdout  
            os.dup2(slave, 2)  # stderr
            os.close(slave)
            
            stdout, stderr, code = run()
            print(f"STDOUT:\n{stdout}")
            print(f"STDERR:\n{stderr}")
            print(f"EXIT CODE: {code}")
            sys.exit(code)
        else:  # Parent process
            os.close(slave)
            time.sleep(2)  # Give nvim time to start
            
            # Read output
            try:
                output = os.read(master, 4096).decode('utf-8', errors='ignore')
                print(output)
            except OSError:
                pass
            
            # Wait for child
            _, status = os.waitpid(pid, 0)
            return os.WEXITSTATUS(status)
            
    finally:
        try:
            os.close(master)
        except OSError:
            pass

if __name__ == '__main__':
    exit_code = run_nvim_in_pty()
    sys.exit(exit_code)