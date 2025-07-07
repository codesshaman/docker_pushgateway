#!/bin/bash

NAME="$(grep "GIT_USER" .env | sed -r 's/.{,9}//')"
MAIL="$(grep "GIT_MAIL" .env | sed -r 's/.{,9}//')"

git config user.name "$NAME"

git config user.email "$MAIL"

git config --local --list
