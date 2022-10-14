# How to run Contakti during development

You can manually fire up the daemons (services) on your Linux,
or use the devrunner.sh script in this folder.

If you use the script, install 'tmux' on Linux:
```
    apt-get install tmux
```

## Using the devrunner.sh for the first time

Configure the script. It's easy: there is just one place where
you need to define a path:

projroot="..."

Example, if you develop in /home/jack/prg/contakti

then set the line

projroot="/home/jack/prg/contakti"

Now you're ready to run it.

```
    ./devrunner.sh
```

Wait for a second. Once tmux is ready and has three windows running, you can
access Contakti in the address mentioned in devrunner.sh (see bottom)

## In case devrunner.sh gives tmux-related problems

Remove (rm) any tmux-*.log files in the project folder.

Eg.
   cd YourProject
   rm tmux-*.log

