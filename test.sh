#!/bin/bash
source ~/nvm/nvm.sh
nvm install 0.8.25
nvm use 0.8.25
npm install
npm test
