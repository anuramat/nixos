#!/usr/bin/env bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ System settings ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# shoutout to https://macos-defaults.com
# and https://mths.be/macos
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
screenshot_dir="$HOME/Screenshots"
ensure_path "$screenshot_dir"
osascript -e 'tell application "System Preferences" to quit' # So it doesn't interfere
# Finder
defaults write com.apple.finder ShowStatusBar -bool true
defaults write -g AppleShowAllExtensions -bool true                         # Show file extensions
defaults write com.apple.finder CreateDesktop -bool false                   # Hide icons from desktop
defaults write com.apple.finder FXDefaultSearchScope -string SCcf           # Search current folder by default
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false  # Hide warning on extension change
defaults write com.apple.finder FXPreferredViewStyle -string clmv           # Set default view to columns
defaults write com.apple.finder ShowPathbar -bool true                      # Show bar on the bottom
defaults write com.apple.finder _FXSortFoldersFirst -bool true              # Keep folders on the top
defaults write com.apple.finder QuitMenuItem -bool true                     # Allow quit on Cmd+Q
defaults write com.apple.universalaccess showWindowTitlebarIcons -bool true # Show folder icon in title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
killall Finder
# sadf
defaults write com.apple.finder NewWindowTarget -string "PfDe"                        # "PfDe" for desktop, "PfDo" for documents..., "PfLo" otherwise
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/" # file://${PATH}/
# Dock
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true                 # Hide dock
defaults write com.apple.dock autohide-delay -float 0             # Remove unhide delay
defaults write com.apple.dock autohide-time-modifier -float 0     # Remove hide/unhide animation
defaults write com.apple.dock mineffect -string scale             # Set minimize animation
defaults write com.apple.dock mru-spaces -bool false              # Do not rearrange spaces automatically
defaults write com.apple.dock show-recents -bool true             # Do not show recent apps
defaults write com.apple.dock static-only -bool true              # Only show opened apps
defaults write com.apple.dock show-process-indicators -bool false # Hide indicater for open applications
defaults write com.apple.dock expose-group-apps -bool true        # Group windows by application
defaults write com.apple.dock persistent-apps -array              # Delete all apps shortcuts
killall Dock
# not tested : don't write dsstore on external drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Misc
defaults write -g AppleSpacesSwitchOnActivate -bool false                 # Switch to space with open application on Cmd+Tab
defaults write -g AppleInterfaceStyle Dark                                # Dark mode
defaults write -g ApplePressAndHoldEnabled -bool false                    # Allow key repeat on hold
defaults write com.apple.screencapture location -string "$screenshot_dir" # Set screenshot folder
defaults write com.apple.TextEdit RichText -bool false                    # Use txt by default (&& killall TextEdit ?)
defaults write -g AppleWindowTabbingMode -string always                   # Prefer tabs to windows
defaults write -g NSCloseAlwaysConfirmsChanges -bool false                # Ask to save on close
defaults write -g NSQuitAlwaysKeepsWindows -bool false                    # Close windows on <Cmd-Q>
# Keyboard
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g TISRomanSwitchState -bool false # turn off automatic input method switching
defaults write -g InitialKeyRepeat -float 15      # repeat period
defaults write -g KeyRepeat -float 2              # delay
# Language
defaults write -g AppleLanguages -array en  # Change system language
defaults write -g AppleLocale -string en_RU # TODO test
# TODO add more
sudo languagesetup -langspec English # login language