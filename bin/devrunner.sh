#!/bin/sh

# Contakti helper script for developers:
# quickly "runs the Contakti on Ruby" (ie. 3 services)
#
# Requires: 'tmux' tool installed on your Linux
#
# Since the Contakti needs to have 3 services (Puma, Sidekiq, and Rails) running,
#
# Set the name of the folder where your mobile legacy code is
projroot="/Users/anikulshin/Projects/contakti/"
#
# START RUNNING
#
cd $projroot
# We need to be on the root folder of Contakti
#
# Identify our location by the file content
if [ ! -f ./Rakefile ]; then
  echo "You are probably not in the right place."
  echo "cd into the Contakti root folder."
  echo "It is identified (among others) by a ./Rakefile"
  echo "and a README.md"
  exit 1
fi

# Check tool requirements

command -v tmux >/dev/null 2>&1 || {
  echo >&2 "I need tmux tool installed"
  echo "Install with 'apt-get install tmux' (or similar liturgy)"
  exit 1
}

# Start running 3 services in one tmux session

tmux new-session -d 'Contakti mobile (leg)'
tmux split-window -v 'bundle exec sidekiq'
tmux split-window -v 'bundle exec puma danthes.ru -e development'
tmux split-window -v 'bundle exec thin start -p 3001 --ssl --ssl-key-file .ssl/localhost.key --ssl-cert-file .ssl/localhost.crt'
exit 0

# Run the below commands in 1 per window:
# bundle exec puma danthes.ru -e development
# bundle exec sidekiq
# bundle exec thin start -p 3001 --ssl --ssl-key-file .ssl/localhost.key --ssl-cert-file .ssl/localhost.crt

#
# After which the Contakti service can be loaded with web browser from:

# Desktop version
# https://localhost.ssl:3001/

# Mobile front-end
# https://localhost.ssl:3001/mobile/
