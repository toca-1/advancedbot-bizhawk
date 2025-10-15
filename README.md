AdvancedBot is a Lua script to be used with **BizHawk** & **TAStudio**, currently written only with GBA games in mind, and the name is an hommage to [BasicBot](https://tasvideos.org/Bizhawk/BasicBot). AdvancedBot searches for the earliest frame (within a fixed window) where the value of a given address changes, while holding:
- a set of always-held buttons for the whole window, plus
- one sweep button for a **consecutive** run of k frames inside that window.

The bot records the inputs for which the fastest change happens (and posts a corresponding log message) and, at the end, inserts the fastest one into the selected branch within TAStudio (if enabled)

## Requirements
BizHawk 2.11 with TAStudio enabled

## How to Run
1. Download [advancedbot.lua](https://raw.githubusercontent.com/toca-1/advancedbot-bizhawk/main/advancedbot.lua) (right-click and select "Save Link As...")
2. In BizHawk: *Tools > Lua Console > Script > Open Script...* and select the file
3. Fill the UI fields and click *Run sweep*

## Demo
Watch a video of the bot in action by [clicking here](https://www.youtube.com/watch?v=VKQaV8AZy2k)

## How it works
1. The bot reloads the selected TAStudio branch before each run.
2. Inputs begin on the frame the branch is loaded
3. Inputs are written straight into TAStudio
4. After each frame in the window the bot reads the address given by the user. If the value differs from its initial value, that frame is recorded as a change.  
5. Across all trials, the earliest frame with a change is reported. If the *Input best* checkbox is enabled, the best inputs are written back into TAStudio at the selected branch

## UI
To get detailed info on the UI, click "About" at the bottom of the AdvancedBot window. This opens an additional window with further information and explanations.

## Console output
The Bizhawk console logs all best attempts, including:
- Earliest variable change at absolute frame X
- Duration of frames the sweep button is held (`k`), and what frame it starts on relative to the first frame of the testing window (`s`)
- Assuming any change was found at all, the final message also reminds you which buttons were held always, and what the sweep button was
- If "output ties" is selected, then not only the best attempts but also attempts which tie the current best are output to the console
- If "2nd address" is checked, then every (tied) best in the console also features the value at the secondary address at the end of the testing window

## Tips & tricks
Ways to speed up the search:
- Unthrottle the clock for maximum emulation speed (Config > Speed/Skip > Unthrottled)
- If the frame window that's being tested is currently visible in TAStudio that slowed the emulator down by as much as 50%. In turn, this means that you can double the testing speed by scrolling up or down in TAStudio until none of the visible frames are part of the frames that are currently being tested by the bot

## Disclaimer: AI assistance
Parts of this script were created with help from ChatGPT (GPT-5 Thinking). Yet, I want to stress that I reviewed, tested, and take responsibility for the final code

## License
MIT
