#!/bin/bash
adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED --ez read_only -d file://sdcard/Movies

