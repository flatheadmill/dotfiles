#!/bin/bash

[[ $(jq -r ".name" < package.json) = "proof" ]] || [[ $(jq -r '.devDependencies.proof' < package.json) = "3.0.x" ]]

