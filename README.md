# Pocket DAW

## Description

A simple digital audio workstation to record and edit a sequence of sounds with different pitch. The project is developed with use of Flutter technology and is located in *daw_with_ffi* directory.

## Features

- Support for Android and Linux
- Internationalization
- Managing DAW project files
- Exporting audio via a native library

## Packages used

- *just\_audio*: plays audio from memory
- *file\_manager*: a widget to pick files and directories
- *permission\_handler*

## Supported audio files

This app only supports standard WAVE PCM soundfiles with **16 bits** per sample.

## Installation

On Linux, install *libmpv-dev*.

## Example projects

*daw* directory contains example source files and projects. On Android, place the directory into the **internal storage** \(*\/storage\/emulated\/0\/*\). On Linux, run the command <kbd>./prepare\_projects.sh</kbd>

## Instruction

- Hold a button to see the tooltip.
- Either open an existing project or select a *.wav* file as a source. See which formats are supported. **Request permissions to see files \(on the first run\)**.
- Start recording.
- Play the piano.
- Stop recording.
- Open the timeline and edit the recorded track. **Reopen this section to see changes**.
- Add a new source.
- Select an active source in *Tracks* section.
- Save the project. This will create *daw\_out.txt* in the selected directory.
- Export the project. This will create *daw\_out.wav* in the selected directory (takes up to **60 MiB**).
