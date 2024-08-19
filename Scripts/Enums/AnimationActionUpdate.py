import json 

ENUMS_JSON_OUTPUT = "Scripts/Enums/Enums.json"
ANIMATION_ACTION_KEY = "AnimationAction"

keyOpener = '["'
keyCloser = '"]'
with open("src/Shared/AnimationSet.lua", "r") as file:
    enumsInput = json.load(open(ENUMS_JSON_OUTPUT, "r"))
    
    lines = file.readlines()
    isInsideTable = False
        
    if not ANIMATION_ACTION_KEY in enumsInput.keys():
        enumsInput[ANIMATION_ACTION_KEY] = []
    else:
        enumsInput[ANIMATION_ACTION_KEY].clear()

    for line in lines:
        if line.find("{"):
            isInsideTable = True
        elif line.find("}"):
            isInsideTable = False
        
        if isInsideTable:
            variable = line.replace("\n", "").replace("\t", "").split("=")

            for importedKey in variable:
                if importedKey.find(keyOpener) >= 0 and importedKey.find(keyCloser) >= 0:
                    importedKey = importedKey.replace(keyOpener, '').replace(keyCloser, '').replace(' ', '')
                else:
                    importedKey = None

                if importedKey:
                    enumsInput[ANIMATION_ACTION_KEY].append(importedKey)
                    #print(importedKey)
       # print("".join(line.split('["')).replace("\n", "").replace("\t", "").split('"]'))
    json.dump(
        obj= enumsInput, 
        fp= open(ENUMS_JSON_OUTPUT, "w")
    )
