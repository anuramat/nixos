#!/usr/bin/env bash

case "$1" in
	*OTP*)
		pass-cli item totp --item-title 'bwuni cluster' --output json | jq '.totp' -r
		;;
	*[Pp]assword*)
		pass-cli item view --item-title 'bwuni cluster' --output json | jq '.item.content.content.Login.password' -r
		;;
	*) exit ;;
esac
