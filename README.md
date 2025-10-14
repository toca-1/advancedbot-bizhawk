AdvancedBot is a Lua script to be used with **BizHawk** & **TAStudio**. It is currently written only with GBA games in mind (tested on BizHawk 2.11). It searches for the earliest frame (within a fixed window) where the value of a given address changes, while holding:
- a set of always-held buttons for the whole window, plus
- one sweep button for a consecutive run of k frames inside that window.

It records the inputs for which the fastest change happens (and posts a corresponding log message) and, at the end, inserts the fastest one into the selected branch within TAStudio (if enabled)

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

## UI reference
- **Total duration (in frames):** The window size to simulate per trial
- **Min/Max # of sweep frames:** Further limit the search space so only sweep-button sequences of length `k_min ≤ k ≤ k_max` are tested. If left empty, `k_min = 0` and `k_max = total duration`
- **Trials / Frames / FPS value / Est. time / Update:** Gives an idea of how long the sweep will take. The FPS value must be entered manually; *Est. time* updates only when *Update* is clicked.  
- **Always-held buttons:** Buttons held for every frame of the window in every trial
- **Sweep button:** The button tested for `k` consecutive frames within the window
- **TAStudio Branch:** Which TAStudio branch should be used for testing. The frame of that branch is also the **first frame** of the testing window
- **Input best:** If checked, after the sweep finishes (and a best is found), the bot reloads the branch once more and writes the best input sequence into TAStudio
- **Run sweep:** Starts the sweep using the given values
- **Pause sweep:** Toggles pause/resume of the script
- **Close window:** Stops the sweep and closes the window
- **About:** Opens the "About" window with further information

## Console output
The Bizhawk console logs all best attempts, including:
- Earliest variable change at absolute frame X
- Duration of frames the sweep button is held (`k`), and what frame it starts on relative to the first frame of the testing window (`s`)
- Assuming any change was found at all, the final message also reminds you which buttons were held always, and what the sweep button was

## Disclaimer: AI assistance
Parts of this script were created with help from ChatGPT (GPT-5 Thinking). Yet, I want to stress that I reviewed, tested, and take responsibility for the final code

## License
MIT
