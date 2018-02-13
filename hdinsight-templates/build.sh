#!/bin/bash
rm -rf target
mkdir target
zip -r integrationtohdinsight.zip . -x '.DS_Store*' -x '.git*' -x 'target*' -x 'node_modules*'

mv integrationtohdinsight.zip target/
