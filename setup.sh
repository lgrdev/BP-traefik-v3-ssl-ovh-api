#!/bin/bash

# create and protect the acme.json file
echo "Setting up permissions..."
touch $PWD/letsencrypt/acme.json
chmod 600 $PWD/letsencrypt/acme.json

# prepare secrets files
echo "Creating secrets files..."
for file in $PWD/secrets/*.sample; do
  mv "$file" "${file%.exemple}.secret"
done

# prepare environment files
echo "Creating environment files..."
mv $PWD/.env.sample $PWD/.env

# you are ready to go
echo "Setup complete!"
echo "Don't forget to update the .env file with your own values."
echo "Don't forget to update the secret files with your own values."
echo "You can now run 'docker-compose up -d' to start the service."
echo "Have fun!"

