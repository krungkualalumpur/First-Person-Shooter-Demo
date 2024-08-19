#!/bin/bash
python Scripts/Enums/AnimationActionUpdate.py
python "../Enum-Automation/Scripts/EnumAutomation.py" Scripts/Enums/Enums.json src/Shared/Enums.lua
rojo sourcemap default.project.json --output sourcemap.json