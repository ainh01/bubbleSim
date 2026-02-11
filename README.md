# BubbleSim &middot; [![npm](https://img.shields.io/npm/v/npm.svg?style=flat-square)](https://www.npmjs.com/package/npm) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/ainh01/bubbleSim/blob/master/LICENSE)  
> An automated farming script for Bubble Simulator on Roblox.  

This project is a Lua script designed to automate various tasks within the Roblox game Bubble Simulator, including auto-bubbling, auto-selling, item collection, and claiming rewards.  

## Installing / Getting started  

To use this script, inject it into Roblox using a Lua executor.  

```lua  
loadstring(game:HttpGet("https://raw.githubusercontent.com/ainh01/bubbleSim/main/main.lua"))()  
```  

This command downloads the `main.lua` script from the GitHub repository and executes it within the Roblox environment. A graphical user interface (GUI) will then appear in-game, allowing you to control the automation features.  

## Developing  

### Built With  
* Roblox Lua (Luau)  

### Prerequisites  
* A Roblox exploit/executor to run Lua scripts in-game.  

### Setting up Dev  

To set up the development environment:  

```shell  
git clone https://github.com/ainh01/bubbleSim.git  
cd bubbleSim/  
```  

This clones the repository to your local machine. You can then open `main.lua` in your preferred text editor to make modifications.  

### Building  

No specific build steps are required for this project beyond saving your `.lua` file. The script is directly interpreted by the Roblox Lua environment.  

### Deploying / Publishing  
To "deploy" a new version of the script:  

1. Push your changes to the GitHub repository:  
   ```shell  
   git add .  
   git commit -m "Your commit message"  
   git push origin main  
   ```  
2. The `loadstring` command will automatically pull the latest `main.lua` from the `main` branch.  

## Versioning  

For the versions available, see the [tags on this repository](https://github.com/ainh01/bubbleSim/tags).  

## Configuration  

The script includes an in-game GUI with several configurable options:  

*   **Auto Bubble**: Automatically blows bubbles.  
*   **Auto Sell Bubble**: Automatically sells bubbles when near a selling point.  
*   **Sell Delay**: Sets the time delay between selling bubbles.  
*   **Auto Collect**: Automatically collects items within a defined range.  
*   **Collection Range**: Sets the distance within which items are collected.  
*   **Collection Delay**: Sets the time delay between collection attempts.  
*   **Special Island Teleport**: Select an island from a dropdown and teleport to it.  
*   **Auto Giant Chest**: Automatically claims Giant Chest rewards.  
*   **Auto Void Chest**: Automatically claims Void Chest rewards.  
*   **Auto Free Spin**: Automatically collects free wheel spins.  
*   **Auto Dog Jump**: Automatically collects dog jump rewards.  
*   **Auto Playtime**: Automatically collects playtime rewards.  
*   **Auto Alien Merchant**: Automatically buys from the Alien Merchant.  
*   **Auto Black Merchant**: Automatically buys from the Black Merchant.  
*   **Auto Claw**: Automates the Claw game in Season 2.  
*   **Auto Close**: Automatically closes notification prompts.  
*   **Auto Board Dice**: Automates the Board Dice game in Season 2.  
*   **Auto Card game**: Automates the Card game in Season 2.  
*   **Auto Doggy Cart game**: Automates the Doggy Cart game in Season 2.  
*   **GUI Transparency**: Adjusts the transparency of the GUI.  
*   **Window Position**: Resets the GUI position to the center of the screen.  
*   **Save Configuration**: Saves current settings to `bubbleSimConfig.json` (requires local file writing capabilities from your executor).  

## Tests  

No automated tests are included. Testing is performed manually within the Roblox game environment.  

## Style guide  

The code generally follows a consistent Lua style, with clear variable names and function definitions. Indentation uses tabs for readability.  

## Api Reference  

This project interacts directly with the Roblox game's internal `ReplicatedStorage` services and remotes. There is no external API. Key remote functions used include:  

*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("BlowBubble")`: Initiates bubble blowing.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("SellBubble")`: Initiates bubble selling.  
*   `ReplicatedStorage.Remotes.Pickups.CollectPickup:FireServer(itemId)`: Collects a specific item.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("ClaimChest", chestType, true)`: Claims chest rewards.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("ClaimFreeWheelSpin")`: Claims free wheel spins.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("DoggyJumpWin", amount)`: Claims Dog Jump rewards.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Function:InvokeServer("ClaimPlaytime", rewardId)`: Claims Playtime rewards.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("BuyShopItem", shopName, itemIndex)`: Buys items from a shop.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer("Teleport", worldPath)`: Teleports to a specified location.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer('StartMinigame', minigameName, difficulty)`: Starts a minigame.  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer('GrabMinigameItem', itemId)`: Grabs an item in a minigame (e.g., Claw).  
*   `ReplicatedStorage.Shared.Framework.Network.Remote.Event:FireServer('FinishMinigame')`: Finishes a minigame.  

## Database  

This project does not use a separate database. It interacts with the game's existing data structures and remote events. Configuration settings are saved locally as a JSON file (`bubbleSimConfig.json`) if the executor supports file writing.  

## Licensing  

This project is licensed under the MIT License - see the [LICENSE](https://github.com/ainh01/bubbleSim/blob/main/LICENSE) file for details.
