# Godot-Virtual-Joystick
A simple virtual joystick for touchscreens, for both 2D and 3D games, with useful options.

<p align="center"> 
	<img src="https://raw.githubusercontent.com/MarcoFazioRandom/Virtual-Joystick-Godot/master/preview_icon.png" width="300">
	<img src="https://raw.githubusercontent.com/MarcoFazioRandom/Virtual-Joystick-Godot/master/preview_1.png" width="400">
</p>

Made with Godot Engine: https://godotengine.org



#### Notice:
I found an annoying bug with Godot's input system so for now I can't say this project is 100% done, when the bug will be fixed I'll clean the code and perfection the joystick.
About the bug: 
in the _gui_input() function the event InputEventScreenTouch is bugged when using the touch, because it only read the touch when is pressed but not when it's released. I will report this bug hoping it will be fixed soon.



### OPTIONS:  

<img src="https://raw.githubusercontent.com/MarcoFazioRandom/Virtual-Joystick-Godot/master/preview_2.png" width="300">

- Joystick mode: 
	- Fixed: The joystick doesn't move. 
	- Dynamic: Every time the joystick area is pressed, the joystick position is set on the touched position. 
	- Following: If the finger moves outside the joystick background, the joystick follows it.  

- Vector mode: 
	- Real: return a vector with a lenght beetween 0 and 1; useful for implementing different velocity or acceleration.  
	- Normalized: return a normalized vector. 

- Directions: The number of directions, e.g. a D-pad is joystick with 4 directions, keep 0 for a free joystick.  
- Simmetry Angle: the angle of simmetry of the directions.  

- Dead zone: If the handle is inside this range, in proportion to the background size, the output is zero.

- Clamp zone: The max distance the handle can reach, in proportion to the background size.

### HELP:  
- The Control parent of the joystick is the area in which the joystick can move in Dynamic or Following mode.  
- For moving the joystick inside is area, select it, right click and turn on "Editable Children" and simply move the 'Background' node.  - With "Editable Children" turned on you can also edit the joystick textures and colors.  
- An example scene is provided in the "Test" folder.  
- To be able to use the joystick with the mouse, you have to go to Project settings -> Input Devices -> Pointing, and turn on the option "emulate touch from mouse".  

### HOW TO USE:  
Create a CanvasLayer node and name it "UI", it'll contain all the UI elements, then add the Joystick scene as a child of the UI node and move it where you prefer (remember to turn on "Editable Children"). 
