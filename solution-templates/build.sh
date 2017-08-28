#!/bin/bash

#Clean
rm -rf target
mkdir target

#Make
function makeZipNotWar() {
    OFFER_NAME=$1;
    sed -i -e "s/STRIIM_OFFER/$OFFER_NAME/" mainTemplate.json 
    sed -i -e "s/STRIIM_OFFER/$OFFER_NAME/" createUiDefinition.json
    rm -r *.json-e
    zip -r $OFFER_NAME.zip . -x '.DS_Store*' -x '.git*' -x 'target*' -x 'node_modules*'
    mv $OFFER_NAME.zip target/
    git checkout mainTemplate.json
    git checkout createUiDefinition.json

}

makeZipNotWar integrationforsqlserveronazure
makeZipNotWar integrationtohdinsight
makeZipNotWar integrationtoazurestorage
makeZipNotWar integrationtoeventhub






